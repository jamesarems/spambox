# word stemming engine for SPAMBOX V2 (2.0.[1/2]_3.2.14 or higher)
# copyright Thomas Eckardt 08/08/2013 , 2014
#
# This module has to be installed in the lib path of the spambox directory
# It stemms the words of a mail for the languages listed below.
# The installation of the Perl modules Lingua::Stem::Snowball and Lingua::Identify
# is required to use this word stemmer.
# Using this module will improve the correctness of the SPAMBOX Bayesian analyze and
# the result of the rebuild spamDB task.
#
# If you have problem using this module or you want to see the stemming results,
# change the variable $debug and/or $logging to your needs.

package SPAMBOX_WordStem;
use strict;
use Encode();

use Lingua::Stem::Snowball();
use Lingua::Identify qw(langof name_of set_active_languages);

use constant FB_SPACE => sub { '' };

our $VERSION = '1.27';

our $debug = 0; # 0 or 1
our $last_lang_detect;

our $canStopWords = eval('use Lingua::StopWords; 1;');

# exceptions for words included by &main::clean
# exception words will be replaced as follows:
our %exeptions = (
'rcpt' => 'rcpt',
'sender' => 'sender',
'helo:' => 'helo:',
'hlo' => 'hlo',
'Subject:' => 'Subject:',
'href' => 'href',
'atxt' => 'atxt',
'lotsaspaces' => 'lotsaspaces',
'ssub' => 'ssub',
'jscripttag' => 'jscripttag',
'boldifytext' => 'boldifytext',
'randword' => 'randword',
'randcolor' => 'randcolor',
'randdecnum' => 'randdecnum',
'randnumber' => 'randnumber',
'randwildnum' => 'randwildnum',
'linkedimage' => 'linkedimage',
'blines' => 'blines',
'quote' => 'quote'
);

our $logging;

=head1 Supported Languages

The following stemmers are available (as of Lingua::Stem::Snowball 0.95):

    |-----------------------------------------------------------|
    | Language   | ISO code | default encoding | also available |
    |-----------------------------------------------------------|
    | Danish     | da       | ISO-8859-1       | UTF-8          |
    | Dutch      | nl       | ISO-8859-1       | UTF-8          |
    | English    | en       | ISO-8859-1       | UTF-8          |
    | Finnish    | fi       | ISO-8859-1       | UTF-8          |
    | French     | fr       | ISO-8859-1       | UTF-8          |
    | German     | de       | ISO-8859-1       | UTF-8          |
    | Hungarian  | hu       | ISO-8859-1       | UTF-8          |
    | Italian    | it       | ISO-8859-1       | UTF-8          |
    | Norwegian  | no       | ISO-8859-1       | UTF-8          |
    | Portuguese | pt       | ISO-8859-1       | UTF-8          |
    | Romanian   | ro       | ISO-8859-2       | UTF-8          |
    | Russian    | ru       | KOI8-R           | UTF-8          |
    | Spanish    | es       | ISO-8859-1       | UTF-8          |
    | Swedish    | sv       | ISO-8859-1       | UTF-8          |
    | Turkish    | tr       | UTF-8            |                |
    |-----------------------------------------------------------|

=cut

# set the logging level
# 0 - no logging
# 1 - error logging only
# 2 - enhanced logging
# 3 - enhance logging and creates two files in spamboxBASE/lingua/
#     ...i - the input words
#     ...o - the output words
$logging = 1;

our @langs = ('da','de','en','fi','fr','hu','it','nl','no','pt','ro','ru','es','sv','tr');  # Lingua::Stem::Snowball

# called inside sub clean from spambox.pl
# gets a string with words or a string reference
# returns the normalized string or undef in case of an error or an undetectable language
sub process {
    d('SPAMBOX_WordStem::process');
    my $text = ref $_[0] ? ${$_[0]} : $_[0];
    eval {
    $last_lang_detect = undef;
    return if (! $text);
    if (! &main::is_7bit_clean(\$text) && ! Encode::is_utf8($text)) {
        &main::mlog(0,"info: WordStem tries to correct utf8 mistakes") if $logging > 1;
        Encode::_utf8_on($text);
        $text = eval {Encode::decode('utf8', Encode::encode('utf8', $text), FB_SPACE)} if (! Encode::is_utf8($text,1));
    }
    
    my $langtext = $text;
    
    # remove any htlm tags and reserved words from text to get better results in language detection
    d('SPAMBOX_WordStem - cleanup HTML Tags');
    $langtext =~ s/<[^>]*>//gos;
    d('SPAMBOX_WordStem - cleanup exception words');
    foreach my $word (keys %exeptions) {
        $langtext =~ s/(\b)$word\b/$1/ig;
    }
    return unless $langtext;

    my $sep;
    if ($] < 5.016000) {
        $sep = '[^'.$main::BayesCont.']';
    } else {
        $sep = '\P{IsAlpha}';
#        Encode::_utf8_on($text);
#        Encode::_utf8_on($langtext); 
    }
    d('SPAMBOX_WordStem - set_active_languages');
    set_active_languages(@langs);
    
    my @langtext = split(/$sep+/o,$langtext,100); # the first 100 words;
    pop @langtext if @langtext > 100;
    $langtext = join(' ',@langtext);
    d('SPAMBOX_WordStem language detection');
#    @langtext = langof({ method => { smallwords => 0.5, ngrams3 => 1.5 } },$langtext);
    @langtext = langof($langtext);
    my $lang_detect = lc $langtext[0];
    if ($logging) {
        for (my $i = 0; $i < @langtext; $i += 2) {
            my $pc = sprintf("%.2f",$langtext[$i+1] * 100);
            &main::mlog(0,"info: language $langtext[$i] detected to $pc percent") if $logging > 1;
            d("language $langtext[$i] detected to $pc percent");
        }
    }
    if (! $lang_detect) {
        &main::mlog(0,"info: word stemming engine detected no language in mail") if $logging;
        return;
    }

    my $language_name = name_of($lang_detect);
    $last_lang_detect = $language_name;
    &main::mlog(0,"info: word stemming detected language $language_name in mail") if $language_name && $logging > 1;

    &main::mlog(0,"info: word stemming called") if $logging > 1;
    my $t = time;
    my @text;
    if ($logging > 2) {
        -d $main::base.'/lingua' or mkdir $main::base.'/lingua', 775;
        my $fn = $main::base.'/lingua/'.$t.'_in';
        open my $fh,'>',$fn;
        binmode $fh;
        print $fh $text;
        close $fh;
    }

    d('SPAMBOX_WordStem start word stemming');
    my $stemmer = Lingua::Stem::Snowball->new( lang => $lang_detect, encoding => 'UTF-8' );
    if ($canStopWords && (my $stopwords = Lingua::StopWords::getStopWords($lang_detect,'UTF-8'))) {
        &main::mlog(0,'info: SPAMBOX_WordStem process word stem - with StopWords cleanup') if $logging > 1;
        d('SPAMBOX_WordStem process word stem - with StopWords cleanup');
        @text = grep { !$stopwords->{$_} } split(/$sep+/o,$text);
        $text = join(' ',$stemmer->stem(\@text));
    } else {
        my $wordcount = (defined $main::maxBayesValues) ? ($main::maxBayesValues * 2 + 1) : 61;
        @text = split(/$sep+/o,$text,$wordcount);    # 60 words maximum
        $text = (@text > 60) ? ' ' . pop @text : '';  # remove the last unsplitted item
        &main::mlog(0,'info: SPAMBOX_WordStem process word stem - no StopWords cleanup') if $logging > 1;
        d('SPAMBOX_WordStem process word stem - no StopWords cleanup');
        $text = join(' ',$stemmer->stem(\@text)) . $text;
    }
    if ($logging > 2) {
        my $fn = $main::base.'/lingua/'.$t.'_out';
        open my $fh,'>',$fn;
        binmode $fh;
        print $fh $text;
        close $fh;
    }
    d('SPAMBOX_WordStem finished');
    return $text;
    };
}

# backward comp - do nothing
sub clear_stem_cache {
    my @lang = @_;
    return;
}

sub d {
    my $text = shift;
    &main::d($text) if $main::debug or $debug;
}
1;

