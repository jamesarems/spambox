#line 1 "sub main::ChangeMyPassword"
package main; sub ChangeMyPassword {

   my $oldpwd = $qs{old_password};
   my $newpwd = $qs{new_password};
   my $newpwd2 = $qs{new_password2};
   my $hint;
   
   if ($WebIP{$ActWebSess}->{user} eq 'root') {
       my $subst = '<a href="./#webAdminPassword" style="color:#684f00" onmousedown="showDisp(\''.$ConfigPos{webAdminPassword}.'\');gotoAnchor(\'webAdminPassword\');return false;" >' ;
       return <<EOT ;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2><span class="negative">You are root - please go to <a href="./#webAdminPassword" style="color:#684f00" onmousedown="showDisp(\'$ConfigPos{webAdminPassword}\');gotoAnchor(\'webAdminPassword\');return false;" >webAdminPassword</a> to change your password!</span></h2>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
<input name="theButtonLogout" align="right" type="button" value="Logout" onclick="eraseCookie('lastAnchor');window.location.href='./logout';return false;"/>
</form>
</div>
$footers
</body></html>
EOT
   }

   if ($CanUseLDAP && $AdminUsersRight{$WebIP{$ActWebSess}->{user}.'.user.LDAPserver'}) {
       $hint .= 'Your account is configured to use LDAP authentication - your LDAP password will not be changed!<br />';
   }

   if (!$oldpwd && !$newpwd && !$newpwd2) {
       $hint .= 'Please write your old password and the new password two times. The minimum length is 5 characters!';
   } elsif (($newpwd  or $newpwd2) && $newpwd ne $newpwd2) {
       $hint .= '<span class="negative">the new passwords are not equal</span>';
       $newpwd = '';
       $newpwd2 = '';
   } elsif (length($newpwd) < 5) {
       $hint .= '<span class="negative">the new passwords are to short - minimum length is 5 characters</span>';
       $newpwd = '';
       $newpwd2 = '';
   } elsif (Digest::MD5::md5_hex($oldpwd) ne $AdminUsers{$WebIP{$ActWebSess}->{user}}) {
       $hint .= '<span class="negative">wrong old password</span>';
       $oldpwd = '';
       $newpwd = '';
       $newpwd2 = '';
   } elsif ($oldpwd && $oldpwd eq $newpwd) {
       $hint .= '<span class="negative">old and new password are the same - use a different password</span>';
       $newpwd = '';
       $newpwd2 = '';
   } else {
       $AdminUsers{$WebIP{$ActWebSess}->{user}} = Digest::MD5::md5_hex($newpwd);
       $AdminUsersRight{$WebIP{$ActWebSess}->{user}.'.user.passwordLastChange'} = time;
       $AdminUsersRight{$WebIP{$ActWebSess}->{user}.'.user.passwordExp'} = '';
       $WebIP{$ActWebSess}->{isauth} = 1;
       $AdminUsersObject->flush();
       $AdminUsersRightObject->flush();
       return <<EOT ;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2><span class="positive">Your Password was successfuly changed</span></h2>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
<input name="theButtonLogout" align="right" type="button" value="Logout" onclick="eraseCookie('lastAnchor');window.location.href='./logout';return false;"/>
</form>
</div>
$footers
</body></html>
EOT
   }
   

   my $button ='
    <tr>
        <td class="noBorder">&nbsp;</td>
        <td class="noBorder"><input type="submit" name="B1" value="  submit  " /></td>
        <td><input name="theButtonLogout" align="right" type="button" value="Logout" onclick="eraseCookie(\'lastAnchor\');window.location.href=\'./logout\';return false;"/></td>
        <td class="noBorder">&nbsp;</td>
    </tr>';

<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2>Change Your Password</h2>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
    <table class="textBox" style="width: 50%;">
        <tr>
            <td class="noBorder">old password : </td>
            <td class="noBorder">
            <input type="password" size="30" name="old_password" value="$oldpwd"</td>
        </tr>
        <tr>
            <td class="noBorder">new password : </td>
            <td class="noBorder">
            <input type="password" size="30"  name="new_password" value="$newpwd"</td>
        </tr>
        <tr><td class="noBorder">  </td></tr>
        <tr>
            <td class="noBorder">new password : </td>
            <td class="noBorder">
            <input type="password" size="30"  name="new_password2" value="$newpwd2"</td>
        </tr>
        $button
    </table>
</form>
$hint
</div>
$footers
</body></html>
EOT

}
