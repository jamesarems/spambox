#line 1 "sub main::fixUpMIMEHeader"
package main; sub fixUpMIMEHeader {
    my $email = shift;
    return unless ref $email;
    return unless $email->{body_raw};
    return if $email->body_raw =~ /^\s*$/o;
# detect a not defined Content-Type or a not defined boundary in MIME header - but
# having a valid boundary in the body - which makes multiple parts,
# (eg.) attachments and inlines possibly undetected in Email::MIME
    if (! $email->content_type || ! $email->{ct}{attributes}{boundary}) {
        if ($email->body_raw =~ /(?:^|\n)--([^\r\n]+)\r?\n$HeaderRe/so) {
            $email->content_type_set( 'multipart/mixed' ) if $email->content_type !~ /multipart|message/io;
            $email->boundary_set( $1 );
            delete $email->{parts};  # force reparsing the parts
            mlog(0,"info: corrected possibly malformed MIME header for mail analyzing - Content-Type and boundary") if $SessionLog > 2;
        }
    }
}
