#line 1 "sub main::BlockReportGetImage"
package main; sub BlockReportGetImage {
    my $file = shift;
    if ($file =~ /icon/io) {
        -r "$base/images/$file" or
        (mlog(0," BlockReport - unable to open file '$base/images/$file' - using internal image") and return <<'EOT');
R0lGODlhEAAQAPedAEShzke540jB6kfB6ki950SdykWv20a030jB63TR8Uav20e96EecyX+52EWr
1kWl0ky24Eaiz0Odytno8qvQ5d/t9cTo9t/s9EfB68/t+EidyUqcyE/F7kfA6tjp8+Hs9E2l0E7G
7azb78nl8kqw3NXm8Vu02mm63aPW7J7L4kecyL/b64DR7aPY7oTM6YC52ePt9XPR8eXu9fD0+bri
87XV5+Xy+bjg8bjX6brg8ZTD3Uaw27Lf8XLR8Nzq81ulzbHh81aiy3LF5abO5FPC6J/Z77vk9Lbl
9nm42ZHJ43rF5Fylzdjo8VTI7lK54Y7Z88zi73LF5nnE5Ee443TR8Nro8nK32VWx2Xm93l2q0a/S
5kqk0N7r803F7VPF60q/6IXP62q225/d8nnB4fP2+dvp8kOayNvv+Onw9mSp0KLR53jK6vX3+ke+
53/K6NLm8bHj9n3N6lSx2UabyaDM47je78Dc7Euk0HrL6lqkza7a7YW72bni8m2/4cbk8rzY6WvG
6Emw3Pf4+sTe7XzU8nLM7Ei+53TS8HG32dvr86PT6aLP5cPe7X2310u75LDe8XnI59/r86rR5mqu
06HP5U6gy7Te8Ee953TS8UWq1kSl0kOYxk/G7vn5+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAJ0ALAAAAAAQABAA
AAjyADMQ6nEoAaaDCBNQiYEJzpEmXThJnCiRA6cQnJ5Y8IIBwQABHz8K6OARgRgbRlgQabOAgEtD
lxZ8KQTkTBFAPPiAcRRgSoCfax7RiIOnxYEDQkTkcOEEQhRLN9xAOAAJhYEdBkj00TPCTx0lgRQY
UCBFUSYHmdI6uGIik5wTaTONUaPpQV1NePGGqZAEL5ZFAAIHjrAFxB1EiTxQimAlhQQJBSLTYTRo
xRsoWexIQoKj0hwGKhiUGNLgRYNJZjRQuMCGC5MJE8qgSbOptu1NNTrp3j2jUZ4fS4LU3iNj925B
MHxE+vBngw4yxqPvrqJld0AAOw==
EOT
    } else {
        -r "$base/images/$file" or $file = 'logo.gif';
    }
    if (open my $F , '<', "$base/images/$file") {
        binmode $F;
        my @img = <$F>;
        close $F;
        return MIME::Base64::encode_base64( join('',@img) );
    } else {
        mlog(0,"warning: BlockReport - unable to open file '$base/images/$file' - no image available");
        return;
    }
}