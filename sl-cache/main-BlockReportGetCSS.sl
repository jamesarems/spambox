#line 1 "sub main::BlockReportGetCSS"
package main; sub BlockReportGetCSS {
    if (open my $F , '<', "$base/images/blockreport.css") {
        binmode $F;
        my @css = <$F>;
        close $F;
        @css = map {my $t = $_; $t =~ s/\/\*.*?\*\///so; $t =~ s/^\s*\r?\n//o; $t;} @css;
        return '<style type="text/css">' . "\n" . join('',@css). "\n" . '</style>';
    } else {
        mlog(0,"warning: BlockReport - unable to open file '$base/images/blockreport.css' - using internal css");
        my $ret = <<'EOF';
<style type="text/css">
/* the general layout of the Block Report */
a {color:#06c;}
a:hover {text-decoration:none;}
#report {font-family:Arial, Helvetica, sans-serif; font-size:12px; color:#333;}
#report table {width:700px; border:0; border-spacing:0; padding:0; table-layout:fixed;}

/* the layout of the header with the image and the text from blockreport_html.txt */
#header {
 background:#4398c6;
 color:#fff;
 font-weight:normal;
 text-align:left;
 border-bottom:1px;
 solid #369;
 white-space: pre-wrap; /* css-3 */
 white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
 white-space: -pre-wrap; /* Opera 4-6 */
 white-space: -o-pre-wrap; /* Opera 7 */
 word-wrap: break-word; /* Internet Explorer 5.5+ */
}
/* #header table {width:"100%"; border:0; border-spacing:0; padding:0; table-layout:fixed;} */
/* #header th {background:#4398c6; font-weight:normal; text-shadow:0 1px 0 #0C6FA5;} */
#header strong.title {font-size:16px;}
#header img {width:200px; height:75px; border:0; float:left;}

/* the general column definition */
#report td {
 padding:7px;
 background:#f9f9f9;
 border-top:1px solid #fff;
 border-bottom:1px solid #eee;
 line-height:18px;
}

/* the odd column definition (other color) */
#report tr.odd td {
 background:#e0ebf7;
 border-top:1px solid #fff;
 border-bottom:1px solid #c6dcf2;
}

/* the left resend link column */
#report td.leftlink {width: 30px;}

/* the middle column */
#report td.inner {
 width: 630px;
 white-space: pre-wrap; /* css-3 */
 white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
 white-space: -pre-wrap; /* Opera 4-6 */
 white-space: -o-pre-wrap; /* Opera 7 */
 word-wrap: break-word; /* Internet Explorer 5.5+ */
}

/* the right resend link column */
#report td.rightlink {width: 30px;}

/* the title view on hover */
#report td.title {padding:5px; line-height:16px;}
#report td.title strong {font-size:15px;text-shadow:0 1px 0 #0C6FA5;}

/* the date link to open the mail in the browser */
span.date {background:#ddd; padding:1px 2px; color:#555;}
span.date a {color:#333;text-decoration:none;}
span.date a:hover {color:#06c; text-decoration:underline;}

/* the IP link to open the mail in the browser */
span.ip {background:#ddd; padding:1px 2px; color:#555;}
span.ip a {color:#333;text-decoration:none;}
span.ip a:hover {color:#06c; text-decoration:underline;}

/* the 'spam reason'*/
span.spam {color:#b00;}

/* the from and reply to lines*/
span.addr {font-size:10px;text-shadow:0 1px 0 #0C6FA5;}

/* the 'add to whitelist' link */
a.reqlink {color:#06c; font-size:11px;}
a.reqlink img {float:left; margin-right:3px; width:16px; height:16px; border:0;}
</style>
EOF

        $ret =~ s/\/\*.*?\*\///sgo;
        $ret =~ s/(?:\s*\r?\n)/\n/sgo;
        return $ret;
    }
}
