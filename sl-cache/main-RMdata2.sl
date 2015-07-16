#line 1 "sub main::RMdata2"
package main; sub RMdata2 { my ($fh,$l)=@_;
    if($l!~/^ *354/o) {
        RMabort($fh,"data2 Expected 354, got: $l");
    } else {
        my $date=$UseLocalTime ? localtime() : gmtime();
        my $tz=$UseLocalTime ? tzStr() : '+0000';
        $date=~s/(\w+) +(\w+) +(\d+) +(\S+) +(\d+)/$1, $3 $2 $5 $4/o;
        my $this=$Con{$fh};
        sendque($fh,($this->{body}=~/^$HeaderRe/o ? $this->{body} . ($this->{body}=~/\r\n\.[\r\n]+$/o ? '' : "\r\n.\r\n") : <<EOT));
From: $this->{from}\r
To: $this->{to}\r
Subject: $this->{subject}\r
X-Assp-Report: YES\r
Date: $date $tz\r
$this->{mimehead}\r
\r
$this->{body}\r
.\r
EOT
        $Con{$fh}->{getline}=\&RMquit;
    }
}
