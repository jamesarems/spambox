#line 1 "sub main::renderConfigHTML"
package main; sub renderConfigHTML {
  setMainLang();
  my $maillogEnd;
  if ($MaillogTailJump) {
    $maillogEnd = '#MlEnd';
  } else {
    $maillogEnd = '#MlTop';
  }
  $maillogJump = '<a href="javascript:void(0);" onclick="MlEndPos=document.getElementById(\'LogLines\').scrollTop; document.getElementById(\'LogLines\').scrollTop=0; return false;">Go to Top</a><a name="MlEnd"></a>';
  my $IndexPos = $hideAlphaIndex ? '451' : '440';
  my $IndexStart = $hideAlphaIndex ? '452' : '442';
  my $JavaScript;

  my $ConnHint = $WebIP{$ActWebSess}->{lng}->{'msg500100'} || $lngmsg{'msg500100'};

  $plusIcon = 'get?file=images/plusIcon.png';
  $minusIcon = 'get?file=images/minusIcon.png';
  $noIcon = 'get?file=images/noIcon.png';
  $wikiinfo = 'get?file=images/info.png';
 $NavMenu = '
 <hr />
 <div class="menuLevel2">
  <a href="lists"><img src="' . $noIcon . '" alt="noicon" /> White/Redlist/Tuplets</a><br />
  <a href="javascript:void(0);" onclick="popAddressAction();"><img src="' . $noIcon . '" alt="noicon" /> work with addresses</a><br />
  <a href="javascript:void(0);" onclick="popIPAction();"><img src="' . $noIcon . '" alt="noicon" /> work with IP\'s</a><br />
  <a href="recprepl"><img src="' . $noIcon . '" alt="noicon" /> Recipient Replacement Test</a><br />
  <a href="maillog' . $maillogEnd . '"><img src="' . $noIcon . '" alt="noicon" target="_blank" /> View Maillog Tail</a><br />
  <a href="analyze"><img src="' . $noIcon . '" alt="noicon" /> Mail Analyzer</a><br />
  <a href="infostats"><img src="' . $noIcon . '" alt="noicon" /> Info and Stats </a><br />
  ';
  $NavMenu .= '
  <a href="top10stats" target="_blank"><img src="' . $noIcon . '" alt="noicon" /> Top 10 Stats</a><br />' if $DoT10Stat;
  $NavMenu .= '
  <a href="statusspambox?nocache='.time.'" target="_blank"><img src="' . $noIcon . '" alt="noicon" /> Worker/DB/Regex Status</a><br />
  <a href="shutdown_list?nocache='.time.'" target="_blank"><img src="' . $noIcon . '" alt="this monitor will slow down SPAMBOX dramaticly - use it careful" /> SMTP Connections </a>
  <a href="shutdown_list?nocache='.time.'&forceRefresh=1" target="_blank" onmouseover="showhint(\''.$ConnHint.'\', this, event, \'500px\', \'1\');return false;"><img height=12 width=12 src="' . $wikiinfo . '" /></a><br />
  <a href="shutdown"><img src="' . $noIcon . '" alt="noicon" /> Shutdown/Restart</a><br />
  <a href="github"><img src="' . $noIcon . '" alt="noicon" /> GitHUB</a><br /></div>';
 $JavaScript = "
<script type=\"text/javascript\">
<!--
var oldBrowser = false;
/*\@cc_on
   /*\@if (\@_jscript_version < 5.6)
      oldBrowser = true;
   /*\@end
\@*/

if (window.navigator.appName == \"Microsoft Internet Explorer\")
{
   var engine;
   if (document.documentMode) // IE8
      engine = document.documentMode;
   else // IE 5-7
   {
      engine = 5; // Assume quirks mode unless proven otherwise
      if (document.compatMode)
      {
         if (document.compatMode == \"CSS1Compat\")
            engine = 7; //standard mode
      }
   }
   if (engine < 8) {oldBrowser = true;}
}
var BrowserDetect = {
	init: function () {
		this.browser = this.searchString(this.dataBrowser) || \"An unknown browser\";
		this.version = this.searchVersion(navigator.userAgent)
			|| this.searchVersion(navigator.appVersion)
			|| \"an unknown version\";
		this.OS = this.searchString(this.dataOS) || \"an unknown OS\";
	},
	searchString: function (data) {
		for (var i=0;i<data.length;i++)	{
			var dataString = data[i].string;
			var dataProp = data[i].prop;
			this.versionSearchString = data[i].versionSearch || data[i].identity;
			if (dataString) {
				if (dataString.indexOf(data[i].subString) != -1)
					return data[i].identity;
			}
			else if (dataProp)
				return data[i].identity;
		}
	},
	searchVersion: function (dataString) {
		var index = dataString.indexOf(this.versionSearchString);
		if (index == -1) return;
		return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
	},
	dataBrowser: [
		{
			string: navigator.userAgent,
			subString: \"Chrome\",
			identity: \"Chrome\"
		},
		{ 	string: navigator.userAgent,
			subString: \"OmniWeb\",
			versionSearch: \"OmniWeb/\",
			identity: \"OmniWeb\"
		},
		{
			string: navigator.vendor,
			subString: \"Apple\",
			identity: \"Safari\",
			versionSearch: \"Version\"
		},
		{
			prop: window.opera,
			identity: \"Opera\"
		},
		{
			string: navigator.vendor,
			subString: \"iCab\",
			identity: \"iCab\"
		},
		{
			string: navigator.vendor,
			subString: \"KDE\",
			identity: \"Konqueror\"
		},
		{
			string: navigator.userAgent,
			subString: \"Firefox\",
			identity: \"Firefox\"
		},
		{
			string: navigator.vendor,
			subString: \"Camino\",
			identity: \"Camino\"
		},
		{		// for newer Netscapes (6+)
			string: navigator.userAgent,
			subString: \"Netscape\",
			identity: \"Netscape\"
		},
		{
			string: navigator.userAgent,
			subString: \"MSIE\",
			identity: \"Explorer\",
			versionSearch: \"MSIE\"
		},
		{
			string: navigator.userAgent,
			subString: \"Gecko\",
			identity: \"Mozilla\",
			versionSearch: \"rv\"
		},
		{ 		// for older Netscapes (4-)
			string: navigator.userAgent,
			subString: \"Mozilla\",
			identity: \"Netscape\",
			versionSearch: \"Mozilla\"
		}
	],
	dataOS : [
		{
			string: navigator.platform,
			subString: \"Win\",
			identity: \"Windows\"
		},
		{
			string: navigator.platform,
			subString: \"Mac\",
			identity: \"Mac\"
		},
		{
			   string: navigator.userAgent,
			   subString: \"iPhone\",
			   identity: \"iPhone/iPod\"
	    },
		{
			string: navigator.platform,
			subString: \"Linux\",
			identity: \"Linux\"
		}
	]

};
BrowserDetect.init();

var detectedBrowser = 'SPAMBOX-GUI is running in ' + BrowserDetect.browser + ' version ' + BrowserDetect.version + ' on ' + BrowserDetect.OS;
if (oldBrowser) {
    detectedBrowser = detectedBrowser + ' (old javascript engine and/or browser detected)';
}
// -->
</script>

<script type=\"text/javascript\">
<!--

var configPos = new Array();
";
 for my $idx (0...$#ConfigArray) {
   my $c = $ConfigArray[$idx];
   next if(@{$c} == 5);
   $JavaScript .= "configPos['$c->[0]']='$ConfigPos{$c->[0]}';";
 }

$JavaScript .= "
function quotemeta (qstr) {
    return qstr.replace( /([^A-Za-z0-9])/g , \"\\\\\$1\" );
}

function toggleDisp(nodeid)
{
  if (nodeid == null) return false;
  if(nodeid.substr(0,9) == 'setupItem')
    nodeid = nodeid.substr(9);
  layer = document.getElementById('treeElement' + nodeid);
  img = document.getElementById('treeIcon' + nodeid);
  if(layer.style.display == 'none')
  {
    layer.style.display = 'block';
    img.src = '$minusIcon';
    if(document.getElementById('setupItem' + nodeid))
      document.getElementById('setupItem' + nodeid).style.display = 'block';
  }
  else
  {
    layer.style.display = 'none';
    img.src = '$plusIcon';
    if(document.getElementById('setupItem' + nodeid))
      document.getElementById('setupItem' + nodeid).style.display = 'none';
  }
}
function showDisp(nodeid)
{
  if (nodeid == null) return false;
  if(nodeid.substr(0,9) == 'setupItem')
    nodeid = nodeid.substr(9);
  layer = document.getElementById('treeElement' + nodeid);
  img = document.getElementById('treeIcon' + nodeid);
  if(layer.style.display == 'none')
  {
    layer.style.display = 'block';
    img.src = '$minusIcon';
    if(document.getElementById('setupItem' + nodeid))
      document.getElementById('setupItem' + nodeid).style.display = 'block';
  }
}
function gotoAnchor(aname)
{
//    window.location.href = \"#\" + aname;       //
    var currloc = window.location.href.split('#')[0];
    var re = /\\/(maillog|lists|recprepl|infostats|shutdown|analyze|github)/;
    if (re.test(currloc))
    {
        window.location.href = window.location.protocol + '//' + window.location.host + '/#' + aname;
        setAnchor(aname);
        return;
    }
    re = new RegExp('/adminusers',\"i\");
    if (re.test(currloc)) {
//        window.history.replaceState({},'',currloc + '#' + aname);
        window.location.href = currloc + \"#\" + aname;
    }
    else {
        window.location.href = window.location.protocol + '//' + window.location.host + '/#' + aname;
        setAnchor(aname);
    }
}
function expand(expand, force)
{
  counter = 0;
  while(document.getElementById('treeElement' + counter))
  {
    if(!expand)
    {
      //dont shrink if this element is the one passed in the URL
      arr = document.getElementById('treeElement' + counter).getElementsByTagName('a');
      txt = ''; found = 0;
      loc = new String(document.location);
      for(i=0; i < arr.length; i++)
      {
        txt = txt + arr.item(i).href;
        tmpHref = new String(arr.item(i).href);
        if(tmpHref.substr(tmpHref.indexOf('#')) == loc.substr(loc.indexOf('#')))
        {
          //give this tree node the right icon
          document.getElementById('treeIcon' + counter).src = '$minusIcon';
          found = 1;
        }
      }
      if(!found | force)
      {
        document.getElementById('treeIcon' + counter).src = '$plusIcon';
        document.getElementById('treeElement' + counter).style.display = 'none';
        if(document.getElementById('setupItem' + counter))
          document.getElementById('setupItem' + counter).style.display = 'none';
      }
    }
    else
    {
      document.getElementById('treeElement' + counter).style.display = 'block';
      document.getElementById('treeIcon' + counter).src = '$minusIcon';
      if(document.getElementById('setupItem' + counter))
        document.getElementById('setupItem' + counter).style.display = 'block';
    }
    counter++;
  }
}

//make the 'rel's work
function externalLinks()
{
  if (!document.getElementsByTagName)
    return;
  var anchors = document.getElementsByTagName(\"a\");
  for (var i=0; i<anchors.length; i++)
  {
    var anchor = anchors[i];
    if (anchor.getAttribute(\"href\")
      && anchor.getAttribute(\"rel\") == \"external\")
      anchor.target = \"_blank\";
  }
}

// handle cookies to remember something
function createCookie(name,value,days) {
    if (! navigator.cookieEnabled) {return null;}
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = \"; expires=\"+date.toGMTString();
	}
	else var expires = \"\";
	document.cookie = name+\"=\"+value+expires+\"; path=/\";
}

function readCookie(name) {
    if (! navigator.cookieEnabled) {return null;}
	var nameEQ = name + \"=\";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
    if (! navigator.cookieEnabled) {return null;}
	createCookie(name,\"\",-1);
}

function setAnchor(iname)
{
    if (navigator.cookieEnabled) {createCookie('lastAnchor',iname,1);}
//    var rgp = '$RememberGUIPos';
//    if (rgp == '1') {
//        try {
//        if (iname != 'delete') {
//            window.history.replaceState('','','/#'+iname);
//        } else {
//            window.history.replaceState('','','/');
//        }
//        } catch (e) {}
//    }
}

function initAnchor(doIt)
{
    if (doIt != '1') {return null;}
    if (! navigator.cookieEnabled) {return null;}
    var iname = readCookie('lastAnchor');
    if (! iname || iname == '' || iname == 'delete') {return false;}
//    if (window.location.pathname == '/' || window.location.pathname == '') {
        showDisp(configPos[iname]);
        gotoAnchor(iname);
//    } else {
//        return false;
//    }
}
";

  $JavaScript .= "
function docHeight()
{
  if (typeof document.height != 'undefined') {
    return document.height;
  } else if (document.compatMode && document.compatMode != 'BackCompat') {
    return document.documentElement.scrollHeight;
  } else if (document.body && typeof document.body.scrollHeight !='undefined') {
    return document.body.scrollHeight;
  }
}
//********************************************************
//* You may use this code for free on any web page provided that
//* these comment lines and the following credit remain in the code.
//* Floating Div from http://www.javascript-fx.com
//********************************************************
// Modified in May 2005 by Przemek Czerkas:
//  - added calls to docHeight()
//  - added bounding params tlx, tly, brx, bry
var ns = (navigator.appName.indexOf(\"Netscape\") != -1);
var d = document;
var px = document.layers ? \"\" : \"px\";
function JSFX_FloatDiv(id, sx, sy, tlx, tly, brx, bry)
{
  var el=d.getElementById?d.getElementById(id):d.all?d.all[id]:d.layers[id];
  window[id + \"_obj\"] = el;
  if(d.layers)el.style=el;
  el.cx = el.sx = sx;
  el.cy = el.sy = sy;
  el.tlx = tlx;
  el.tly = tly;
  el.brx = brx;
  el.bry = bry;
  el.sP=function(x,y){this.style.left=x+px;this.style.top=y+px;};
  el.flt=function()
  {
    var pX, pY;
    pX = ns ? pageXOffset : document.documentElement && document.documentElement.scrollLeft ? document.documentElement.scrollLeft : document.body.scrollLeft;
    pY = ns ? pageYOffset : document.documentElement && document.documentElement.scrollTop ? document.documentElement.scrollTop : document.body.scrollTop;
    if(this.sy<0)
      pY += ns ? innerHeight : document.documentElement && document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight;
    this.cx += (pX + Math.max(this.sx-pX, this.tlx) - this.cx)/4;
    this.cy += (pY + Math.max(this.sy-pY, this.tly) - this.cy)/4;
    this.cx = Math.min(this.cx, this.brx);
    this.cy = Math.min(this.cy, this.bry);
    if (ns) {
      this.sP(
        Math.max(Math.min(this.cx+this.clientWidth,document.width)-this.clientWidth,this.sx),
        Math.max(Math.min(this.cy+this.clientHeight,document.height)-this.clientHeight,this.sy)
      );
    } else {
      var oldh, newh;
      oldh = docHeight();
      this.sP(this.cx, this.cy);
      newh = docHeight();
      if (newh>oldh) {
        this.sP(this.cx, this.cy-(newh-oldh));
      }
    }
    setTimeout(this.id + \"_obj.flt()\", 20);
  }
  return el;
}" if ($EnableFloatingMenu && ! $mobile);

 $JavaScript .= '
function popFileEditor(filename,note)
{
  var height = (note == 0) ? 500 : (note == \'m\') ? 580 : 550;
  newwindow=window.open(
    \'edit?file=\'+filename+\'&note=\'+note,
    \'FileEditor\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function popAddressAction(address)
{
  var height = 500 ;
  var link = address ? \'?address=\'+address : \'\';
  newwindow=window.open(
    \'addraction\'+link,
    \'AddressAction\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function popIPAction(ip)
{
  var height = 500 ;
  var link = ip ? \'?ip=\'+ip : \'\';
  newwindow=window.open(
    \'ipaction\'+link,
    \'IPAction\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function popSyncEditor(cfgParm)
{
  setAnchor(cfgParm);
  var height = 400;
  newwindow=window.open(
    \'syncedit?cfgparm=\'+cfgParm,
    \'SyncEditor\',
    \'width=600,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function remember()
{
  var height =  580;
  newwindow=window.open(
    \'remember\',
    \'rememberMe\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

window.onload = externalLinks;
// -->
</script>';

# JavaScript for alphabetic IndexMenu
 $JavaScript .= '
<style type="text/css" >
<!--
#smenu {background-color:#ffffff; text-align:left; font-size: 90%; border:1px solid #000099; z-Index:200; visibility:hidden; position:absolute; top:100px; left:-'.$IndexPos.'px; width:450px; height:700px;}
#sleftTop {width:420px; height:5%; float:left;font-size: 90%;color:#999999; font-family:arial, helvetica, sans-serif;overflow: hidden;}
#sleft {width:420px; height:94%; float:left;font-size: 90%;color:#999999; font-family:arial, helvetica, sans-serif;overflow-x: hidden;overflow-y: scroll;}
#sright {width:10px; height:99%; float:right;font-size: 90%;color:#999999; font-family:arial, helvetica, sans-serif;overflow: hidden;}
#sright a:link{text-decoration:none; color:#684f00; font-family:arial, helvetica, sans-serif;}
#sright a:visited{text-decoration:none; color:#684f00; font-family:arial, helvetica, sans-serif;}
#sright a:active{text-decoration:none; color:#684f00; font-family:arial, helvetica, sans-serif;}
#sright a:hover{text-decoration:underline; color:#999999; font-family:arial, helvetica, sans-serif;}
-->
</style>

<script type="text/javascript">
<!--
// Sliding Menu Script
// copyright Stephen Chapman, 6th July 2005
// you may copy this code but please keep the copyright notice as well
// SPAMBOX implementation by Thomas Eckardt
var speed = 1;

function changeSlide() {
    var findText = xDOM(\'quickfind\').value;
    if (findText == \'**select**\') findText = \'\';
    var re;
    try {
        re = new RegExp(findText,"i");
        re.test(\'abc\');
    }
    catch(err) {
        alert(\'error in string (regex) : \'+err);
        return false;
    }
    var entries = xDOM(\'sleft\').getElementsByTagName(\'a\');
    for (var i=0; i<entries.length; i++) {
        var id=entries[i].id;
        if (! id) next;
        if (findText == \'\' || re.test(id.substr(3))) {
            setObjDisp(id,\'inline\');
        } else {
            setObjDisp(id,\'none\');
        }
    }
}

function ClientSize(HorW) {
  var myWidth = 0, myHeight = 0;
  if( typeof( window.innerWidth ) == \'number\' ) {
    //Non-IE
    myWidth = window.innerWidth;
    myHeight = window.innerHeight;
  } else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
    //IE 6+ in \'standards compliant mode\'
    myWidth = document.documentElement.clientWidth;
    myHeight = document.documentElement.clientHeight;
  } else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
    //IE 4 compatible
    myWidth = document.body.clientWidth;
    myHeight = document.body.clientHeight;
  }
  return  HorW == \'w\' ?  myWidth : myHeight;
}

var aDOM = 0, ieDOM = 0, nsDOM = 0; var stdDOM = document.getElementById;
if (stdDOM) aDOM = 1; else {ieDOM = document.all; if (ieDOM) aDOM = 1; else {
var nsDOM = ((navigator.appName.indexOf(\'Netscape\') != -1)
&& (parseInt(navigator.appVersion) ==4)); if (nsDOM) aDOM = 1;}}

function xDOM(objectId, wS) {
  if (stdDOM) return wS ? document.getElementById(objectId).style : document.getElementById(objectId);
  if (ieDOM) return wS ? document.all[objectId].style : document.all[objectId];
  if (nsDOM) return document.layers[objectId];
}
function objWidth(objectID) {var obj = xDOM(objectID,0); if(obj.offsetWidth) return obj.offsetWidth; if (obj.clip) return obj.clip.width; return 0;}
function objHeight(objectID) {var obj = xDOM(objectID,0); if(obj.offsetHeight) return obj.offsetHeight; if (obj.clip) return obj.clip.height; return 0;}
function setObjVis(objectID,vis) {var objs = xDOM(objectID,1); objs.visibility = vis;}
function setObjDisp(objectID,disp) {var objs = xDOM(objectID,1); objs.display = disp;}
function moveObjTo(objectID,x,y) {var objs = xDOM(objectID,1); objs.left = x; objs.top = y;}
function pageWidth() {return window.innerWidth != null? window.innerWidth: document.body != null? document.body.clientWidth:null;}
function pageHeight() {return window.innerHeight != null? window.innerHeight: document.body != null? document.body.clientHeight:null;}
function posLeft() {return typeof window.pageXOffset != \'undefined\' ? window.pageXOffset: document.documentElement.scrollLeft?
 document.documentElement.scrollLeft: document.body.scrollLeft? document.body.scrollLeft:0;}

function posTop() {return typeof window.pageYOffset != \'undefined\' ? window.pageYOffset: document.documentElement.scrollTop?
 document.documentElement.scrollTop: document.body.scrollTop? document.body.scrollTop:0;}

var xxx = 0; var yyy = 0; var dist = distX = distY = 0; var stepx = '.$IndexSlideSpeed.'; var stepy = 0; var mn = \'smenu\';

function disableSlide() {setObjVis(mn,\'hidden\');}
function enableSlide() {setObjVis(mn,\'visible\');}
function distance(s,e) {return Math.abs(s-e)}
function direction(s,e) {return s>e?-1:1}
function rate(a,b) {return a<b?a/b:1}
function setHeight() {var objs = xDOM(mn,1); var h = ClientSize(\'h\'); objs.height = h*0.95 +\'px\';}
function start() {setHeight(); xxx = -'.$IndexStart.'; yyy = 0; var eX = 0; var eY = 100; dist = distX = distance(xxx,eX); distY = distance(yyy,eY); stepx *=
-direction(xxx,eX) * rate(distX,distY); stepy *= direction(yyy,eY) * rate(distY,distX); moveit(); setObjVis(mn,\'visible\');}

function moveit() {var x = (posLeft()+xxx) + \'px\'; var y = posTop() + \'px\'; moveObjTo(mn,x,y);}
function mover() {if (dist > 0) {xxx += stepx; yyy += stepy; dist -= Math.abs(stepx);} moveit(); setTimeout(\'mover()\',speed);}
function slide() {dist = distX; stepx = -stepx; moveit(); setTimeout(\'mover()\',speed*2);return false;}

onload = start;
window.onscroll = moveit;
// -->
</script>
' if (! $mobile);
# END JavaScript for alphabetic IndexMenu

#start JavaScript for HintBox
$JavaScript .= <<EOT;
<style type="text/css">

#hintbox{ /*CSS for pop up hint box */
position:absolute;
top: 0;
background-color: lightyellow;
width: 150px; /*Default width of hint.*/
padding: 3px;
border:1px solid black;
font:normal 11px Verdana;
line-height:18px;
z-index:300;
border-right: 3px solid black;
border-bottom: 3px solid black;
visibility: hidden;

table { table-layout:fixed; word-wrap:break-word; }
}
</style>
EOT

$JavaScript .= '
<script type="text/javascript">

/***********************************************
* Show Hint script- (c) Dynamic Drive (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit http://www.dynamicdrive.com/ for this script and 100s more.
*
* implemented in SPAMBOX by Thomas Eckardt
***********************************************/

var horizontal_offset="0px" //horizontal offset of hint box from anchor link

/////No further editting needed

var vertical_offset="20px" //vertical offset of hint box from anchor link. No need to change.
var ie=document.all
var ns6=document.getElementById&&!document.all

function getposOffset(what, offsettype){
    var totaloffset=(offsettype=="left")? what.offsetLeft : what.offsetTop;
    var parentEl=what.offsetParent;
    while (parentEl!=null){
        totaloffset=(offsettype=="left")? totaloffset+parentEl.offsetLeft : totaloffset+parentEl.offsetTop;
        parentEl=parentEl.offsetParent;
    }
    return totaloffset;
}

function iecompattest(){
    return (document.compatMode && document.compatMode!="BackCompat")? document.documentElement : document.body
}

function clearbrowseredge(obj, whichedge, where){
    var edgeoffset=(whichedge=="rightedge")? (parseInt(horizontal_offset)-obj.offsetWidth*where/2)*-1 : parseInt(vertical_offset)*-1;
    if (whichedge=="rightedge"){
        var windowedge=ie && !window.opera? iecompattest().scrollLeft+iecompattest().clientWidth-90 : window.pageXOffset+window.innerWidth-100;
        dropmenuobj.contentmeasure=dropmenuobj.offsetWidth;
        if (windowedge-dropmenuobj.x < dropmenuobj.contentmeasure)
            edgeoffset=dropmenuobj.contentmeasure+obj.offsetWidth/(where+1)+parseInt(horizontal_offset);
    } else {
        var windowedge=ie && !window.opera? iecompattest().scrollTop+iecompattest().clientHeight-15 : window.pageYOffset+window.innerHeight-18
        dropmenuobj.contentmeasure=dropmenuobj.offsetHeight
        if (windowedge-dropmenuobj.y < dropmenuobj.contentmeasure)
            edgeoffset=dropmenuobj.contentmeasure-obj.offsetHeight+parseInt(vertical_offset)
    }
    return edgeoffset
}

function showhint(menucontents, obj, e, tipwidth, currLoc){
    if (document.getElementById("hintbox")){
        dropmenuobj=document.getElementById("hintbox")
        dropmenuobj.innerHTML=menucontents
        dropmenuobj.style.left=dropmenuobj.style.top=-500
        if (tipwidth!=""){
            dropmenuobj.widthobj=dropmenuobj.style
            dropmenuobj.widthobj.width=tipwidth
        }
        dropmenuobj.x=getposOffset(obj, "left")
        dropmenuobj.y=getposOffset(obj, "top");
        if (currLoc != "" && (ie||ns6)) {
            //var postop = ns6 ? 0 : posTop();
            var postop = 0;
            var objTop = yMousePos+postop+parseInt(vertical_offset);
            var Yedge=ie && !window.opera? iecompattest().scrollTop+iecompattest().clientHeight-15 : window.pageYOffset+window.innerHeight-18;
            if (dropmenuobj.offsetHeight + objTop > Yedge) {
                dropmenuobj.style.top=objTop-dropmenuobj.offsetHeight+"px";
            } else {
                dropmenuobj.style.top=objTop+"px";
            }
        } else {
            dropmenuobj.style.top=dropmenuobj.y-clearbrowseredge(obj, "bottomedge", 0)+"px";
        }
        if (currLoc != "") {
            dropmenuobj.style.left=dropmenuobj.x-clearbrowseredge(obj, "rightedge", 0)+obj.offsetWidth+"px";
        } else {
            dropmenuobj.style.left=dropmenuobj.x-clearbrowseredge(obj, "rightedge", 1)+obj.offsetWidth+"px";
        }
        //alert("x="+dropmenuobj.x+" , cb="+clearbrowseredge(obj, \'rightedge\')+" , offset="+obj.offsetWidth);
        //dropmenuobj.style.left=xMousePos+"px"
        dropmenuobj.style.visibility="visible"
        obj.onmouseout=hidetip
    }
}

function hidetip(e){
    dropmenuobj.style.visibility="hidden"
    dropmenuobj.style.left="-500px"
}

function createhintbox(){
    var divblock=document.createElement("div")
    divblock.setAttribute("id", "hintbox")
    document.body.appendChild(divblock)
}

if (window.addEventListener)
    window.addEventListener("load", createhintbox, false)
else if (window.attachEvent)
    window.attachEvent("onload", createhintbox)
else if (document.getElementById)
    window.onload=createhintbox

// Set Netscape up to run the "captureMousePosition" function whenever
// the mouse is moved. For Internet Explorer and Netscape 6, you can capture
// the movement a little easier.
if (document.layers) { // Netscape
    document.captureEvents(Event.MOUSEMOVE);
    document.onmousemove = captureMousePosition;
} else if (document.all) { // Internet Explorer
    document.onmousemove = captureMousePosition;
} else if (document.getElementById) { // Netcsape 6
    document.onmousemove = captureMousePosition;
}

// Global variables
xMousePos = 0; // Horizontal position of the mouse on the screen
yMousePos = 0; // Vertical position of the mouse on the screen
xMousePosMax = 0; // Width of the page
yMousePosMax = 0; // Height of the page

function captureMousePosition(e) {
    if (document.layers) {
        // When the page scrolls in Netscape, the event\'s mouse position
        // reflects the absolute position on the screen. innerHight/Width
        // is the position from the top/left of the screen that the user is
        // looking at. pageX/YOffset is the amount that the user has
        // scrolled into the page. So the values will be in relation to
        // each other as the total offsets into the page, no matter if
        // the user has scrolled or not.
        xMousePos = e.pageX;
        yMousePos = e.pageY;
        xMousePosMax = window.innerWidth+window.pageXOffset;
        yMousePosMax = window.innerHeight+window.pageYOffset;
    } else if (document.all) {
        // When the page scrolls in IE, the event\'s mouse position
        // reflects the position from the top/left of the screen the
        // user is looking at. scrollLeft/Top is the amount the user
        // has scrolled into the page. clientWidth/Height is the height/
        // width of the current page the user is looking at. So, to be
        // consistent with Netscape (above), add the scroll offsets to
        // both so we end up with an absolute value on the page, no
        // matter if the user has scrolled or not.

        if (window.event) {
            xMousePos = window.event.x+document.body.scrollLeft;
            yMousePos = window.event.y+document.body.scrollTop;
        } else {
            if (e) {};
        }
        xMousePosMax = document.body.clientWidth+document.body.scrollLeft;
        yMousePosMax = document.body.clientHeight+document.body.scrollTop;
    } else if (document.getElementById) {
        // Netscape 6 behaves the same as Netscape 4 in this regard
        xMousePos = e.pageX;
        yMousePos = e.pageY;
        xMousePosMax = window.innerWidth+window.pageXOffset;
        yMousePosMax = window.innerHeight+window.pageYOffset;
    }
}
function browserclose () {
    eraseCookie(\'lastAnchor\');
    confirm(\'please logout first ?\');
    return false;
}
if(window.addEventListener) {
    window.addEventListener("close", browserclose, false);
}

function changeTitle(title) {
    document.title = document.title.replace(/^\S+/ ,title);
}

function WaitDiv()
{
	document.getElementById(\'wait\').style.display = \'block\';
}

function WaitDivDel()
{
	document.getElementById(\'wait\').style.display = \'none\';
}

// JavaScript for reformating the mobile view
function setNavPosition() {
    if (oldBrowser) {document.getElementById(\'topnav\').style.top=\'67px\';}
    document.getElementById(\'topnav\').style.left=\'0px\';
    document.getElementById(\'navMenu\').style.top=document.getElementById(\'topnav\').offsetHeight - (oldBrowser * 18) + \'px\';
    document.getElementById(\'navMenu\').style.left=\'0px\';
}

function showLeftMenu() {
    if (document.getElementById(\'navMenu\').style.display == \'none\') {
        try {
        document.getElementById(\'cfgh2\').style.margin=\'5px 0 0 17em\';
        } catch(e) {}
        try {
        document.getElementById(\'cfgdiv\').style.margin=\'5px 0 0 17em\';
        } catch(e) {}
        document.getElementById(\'topnav\').style.display=\'block\';
        document.getElementById(\'navMenu\').style.display=\'block\';
    } else {
        document.getElementById(\'topnav\').style.display=\'none\';
        document.getElementById(\'navMenu\').style.display=\'none\';
        try {
        document.getElementById(\'cfgh2\').style.margin=\'5px 0 0 0\';
        } catch(e) {}
        try {
        document.getElementById(\'cfgdiv\').style.margin=\'5px 0 0 0\';
        } catch(e) {}
    }
    setNavPosition();
}
';
$JavaScript .= '
var gAutoPrint = true;

function processPrint(){

    if (document.getElementById != null){
        expand(1, 1);
        var html = \'<HTML>\n<HEAD>\n\';
        if (document.getElementsByTagName != null){
            var headTags = document.getElementsByTagName("head");
            if (headTags.length > 0) html += headTags[0].innerHTML;
        }
        html += \'\n</HE\' + \'AD>\n<BODY>\n\';
        html += \'<img src="get?file=images/logo.gif" />&nbsp;&nbsp;&nbsp;<b>SPAMBOX version '.$version.$modversion.'</b><br /><hr /><br />\';

        var printReadyElemCfg  = document.getElementById("cfgdiv");
        var printReadyElemHint = document.getElementById("mainhints");

        if (printReadyElemHint != null)  html += "'.$headerTOC.'";

        if (printReadyElemCfg  != null)  html += printReadyElemCfg.innerHTML;
        if (printReadyElemHint != null)  html += printReadyElemHint.innerHTML;
        if (printReadyElemHint != null)  html += "'.$headerGlosar.'";

        expand(0, 1);
        html += \'\n</BO\' + \'DY>\n</HT\' + \'ML>\';
        var printWin = window.open("","processPrint");
        printWin.document.open();
        printWin.document.write(html);
        printWin.document.close();

        if (gAutoPrint) printWin.print();
    } else alert("Browser not supported.");
}
</script>
' unless $mobile;
$JavaScript .= <<EOT;
<style type="text/css">
#wait {
	position: absolute;
	width: 350;
	heigth: 100;
	margin-left: 300;
	margin-top: 150;
	background-color: #FFF000;
	text-align: center;
	border: solid 1px #FFFFFF;
}
</style>
EOT
#end JavaScript for HintBox

 $headerHTTP = 'HTTP/1.1 200 OK
Content-type: text/html
Cache-control: no-cache
';
 $headerDTDStrict = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
';
 $headerDTDTransitional = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
';
 $headers = "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head>
  <meta http-equiv=\"content-type\" content=\"application/xhtml+xml; charset=utf-8\" />
  <META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">
  <META HTTP-EQUIV=\"Expires\" CONTENT=\"-1\">
  <title>Config SPAMBOX ($myName) Host: $localhostname @ $localhostip</title>
  <link rel=\"stylesheet\" href=\"get?file=images/spambox.css\" type=\"text/css\" />
  <link rel=\"shortcut icon\" href=\"get?file=images/favicon.ico\" />
$JavaScript
</head>
<body window.onunload=\"javascript:browserclose();\" window.onClose=\"javascript:browserclose();\"><a name=\"Top\"></a>
<div class=\"wait\" id=\"wait\" style=\"display: none;\">&nbsp;&nbsp; Please wait while loading... &nbsp;&nbsp;</div>
";

my $hid;
if ( ! $rootlogin) {
    $hid = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
}
if (! $mobile) {
  $headers .= "  <div id=\"smenu\"><div id=\"sleftTop\">&nbsp;
";
# the alpha index
 for ("A"..."Z") {
 $headers .= "<a href=\"#$_\" onmousedown=\"gotoAnchor('$_');return false;\">$_&nbsp;</a>";
 }
 $headers .= "&nbsp;&nbsp;<input id=\"quickfind\" size=\"9\" value=\"**select**\" style=\"background:#eee none; color:#222; font-style: italic\" onfocus=\"if (this.value == '**select**') {this.value='';}\" onchange=\"changeSlide();\" >&nbsp;&nbsp;<img src=\"get?file=images/plusIcon.png\" onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>Select the values to show. The string is searched anywhere in the value names. A regular expression could be used.</td></tr></table>', this, event, '450px', ''); return true;\">&nbsp;&nbsp;&nbsp;<a href=\"javascript:void();\" onclick=\"xDOM('quickfind').value='';changeSlide();return false;\" onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>Click to reset view to default.</td></tr></table>', this, event, '450px', ''); return true;\"><img src=\"get?file=images/minusIcon.png\" ></a>\n<hr></div><div id=\"sleft\">\n";
my %Config1 = ();
while (my ($k,$v) = each %Config) {
    $Config1{lc($k)} = $k;
}
my $firstChar = '';
my $i = 0;
$headerGlosar = "<p style=\"page-break-before: always;\"><br />\n";
$headerGlosar .= '<hr><h2>glosar</h2><hr><br />';
$headerGlosar .= '<table><tr>';
foreach (sort keys %Config1) {
    $i++;
    my $k = $Config1{$_};
    my $name;
    if ( uc($firstChar) ne uc(substr($k,0,1))) {
        $name = 'name="'.uc(substr($k,0,1)).'"';
        $headerGlosar .= '<td>&nbsp;</td>' if ($i != 1 && $i % 2);
        $headerGlosar .= '</tr><tr>' if ($i != 1);
        $headerGlosar .= '<td><br /><br /><b>'.uc(substr($k,0,1))."</b></td><td>&nbsp;</td></tr>\n";
    }
    $headerGlosar .= '<tr>' if ($i % 2);
    my $gI = $glosarIndex{$k};
    $gI = $glosarIndex{'URIBLError'} if $k eq 'TLDS';
    $headerGlosar .= "<td>$k - $gI</td>";
    $headerGlosar .= "</tr>\n" if (!($i % 2));
    $firstChar = uc(substr($k,0,1));
    next if $hid && ! &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$k);
    my $value = $ConfigListBox{$k} ? $ConfigListBox{$k} : encodeHTMLEntities($Config{$k});
    $value =~ s/'|"|\n//go;
    $value =~ s/\\/\\\\/go;
    $value = '&nbsp;' unless $value;
    $value = 'ENCRYPTED' if exists $cryptConfigVars{$k} or $k eq 'webAdminPassword';
    my $default = exists $cryptConfigVars{$k} && $k ne 'webAdminPassword' ? 'ENCRYPTED' : $ConfigDefault{$k};
    $default = '' if $default eq undef;
    $headers .= "<a $name id=\"sl_$k\" onmousedown=\"expand(0, 1);showDisp('$ConfigPos{$k}');gotoAnchor('$k');slide();return false;\" onmouseover=\"window.status='$ConfigNice{$k}'; showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>config var:</td><td>$k</td></tr><tr><td>description:</td><td>$ConfigNice{$k}</td></tr><tr><td>current value:</td><td>$value</td></tr><tr><td>default value:</td><td>$default</td></tr></table>', this, event, '500px', 'index'); return true;\" onmouseout=\"window.status='';return true;\">&nbsp;<img src=\"$noIcon\" alt=\"$ConfigNice{$k}\" />&nbsp;$k<br /></a>\n";
#    $headers .= "<a $name id=\"sl_$k\" href=\"./#$k\" onmousedown=\"expand(0, 1);showDisp('$ConfigPos{$k}');gotoAnchor('$k');slide();return false;\" onmouseover=\"window.status='$ConfigNice{$k}'; showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>config var:</td><td>$k</td></tr><tr><td>description:</td><td>$ConfigNice{$k}</td></tr><tr><td>current value:</td><td>$value</td></tr><tr><td>default value:</td><td>$default</td></tr></table>', this, event, '500px', 'index'); return true;\" onmouseout=\"window.status='';return true;\">&nbsp;<img src=\"$noIcon\" alt=\"$ConfigNice{$k}\" />&nbsp;$k<br /></a>\n";
}
  $headerGlosar .= '<td>&nbsp;</td></tr>' if ($i % 2);
  $headerGlosar .= "\n</table>\n";
  $headerGlosar =~ s/(["\/]|\r?\n)/\\$1/gos;

  
  $headers .= "<br />&nbsp;<br />&nbsp;<br />&nbsp;<br />&nbsp;<br />&nbsp;</div><div id=\"sright\"><a href=\"#\" onclick=\"return slide();return false;\">";
  $headers .= "<img src=\"get?file=images/plusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/minusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/minusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/plusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
# do not use spaces in $boardertext - instead use '#'
  my $boardertext = "sorted#config";
  $boardertext =~ s/([^#])/$1<br \/>/go;
  $boardertext =~ s/#/&nbsp;<br \/>/go;
  $headers .= "$boardertext<br />";
  $headers .= "<img src=\"get?file=images/plusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/minusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/minusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "<img src=\"get?file=images/plusIcon.png\" alt=\"open and close alphabetical index\" /><br />&nbsp;<br \/>";
  $headers .= "</a></div></div>
";

} # end if $mobile -> no index

# the top menu
  $headers .= "<p>";
  $headers .= '<table id="TopMenu" class="contentFoot" style="margin:0; text-align:left;" CELLSPACING=0 CELLPADDING=4 WIDTH="100%">
  <tr><td rowspan="3" align="left">';
  if (-e "$base/images/logo.gif") {
      $headers .= "<a href=\"main\" target=\"_blank\"><img src=\"get?file=images/logo.gif\" alt=\"SPAMBOX\" /></a>";
  } else {
      $headers .= "<a href=\"http://spambox.sourceforge.net/\" target=\"_blank\"><img src=\"get?file=images/logo.jpg\" alt=\"SPAMBOX\" /></a>";
  }
  $headers .= "</td><td rowspan=\"3\" align=\"left\" onmouseover=\"showhint(detectedBrowser,this, event, '450px', '')\">SPAMBOX version $version$modversion<br />";

  if ($setpro && $globalClientName && $globalClientPass) {
      $headers .= "<b><font color=white size=+3>&nbsp;&nbsp;&nbsp;&nbsp;pro</font></b>";
  }

  my $avv = "$availversion";
  my $stv = "$version$modversion";
  $avv =~ s/RC/\./gio;
  $stv =~ s/RC/\./gio;
  $avv =~ s/\s|\(|\)//gio;
  $stv =~ s/\s|\(|\)//gio;
  $stv = 0 if ($avv =~ /\d{5}(?:\.\d{1,2})?$/o && $stv =~ /(?:\.\d{1,2}){3}$/o);
  $headers .= "<br /><a href=\"$NewAsspURL\" target=\"_blank\" style=\"color:green;size:-1;\">new available SPAMBOX version $availversion</a>" if $avv gt $stv;

 $headers .= '</td>
  <td><a href="lists">White/Redlist/Tuplets</a></td>
  <td><a href="recprepl">Recipient Replacement Test</a></td>
  <td><a href="maillog' . $maillogEnd . '">View Maillog Tail</a></td>
  </tr><tr>
  <td><a href="analyze">Mail Analyzer</a></td>
  <td><a href="infostats">Info and Stats</a>';
 $headers .= $DoT10Stat ?
  '<a href="top10stats" target="_blank" onmouseover="showhint(\'show top ten stats\', this, event, \'100px\', \'1\');return false;"><img height=12 width=12 src="' . $wikiinfo . '" /></a></td>'
                       :
  '</td>';
 $headers .= '
  <td><a href="statusspambox?nocache='.time.'" target="_blank">Worker/DB/Regex Status</a></td>
  </tr><tr>
  <td><a href="shutdown_list?nocache='.time.'" target="_blank">SMTP Connections </a>
  <a href="shutdown_list?nocache='.time.'&forceRefresh=1" target="_blank" onmouseover="showhint(\''.$ConnHint.'\', this, event, \'500px\', \'1\');return false;"><img height=12 width=12 src="' . $wikiinfo . '" /></a></td>
  <td><a href="shutdown">Shutdown/Restart</a></td>
  <td><a href="github">GitHUB</a>'.($codename?'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>'.$codename.'</b>':'').'</td>
  </tr>
  </table>
';
# the left top menu
 $headers .= "</p>\n";
 $headers .= "&nbsp;
              <a href=\"javascript:void(0);\" onclick=\"showLeftMenu();return false;\"><small>show/hide the left menu</small></a>
              &nbsp;&nbsp;
              <a href=\"/?mobile=1\"><small>back to main view</small></a>
" if $mobile;
 $headers .= "<div id=\"topnav\" class=\"navMenu\" style=\"position:absolute;text-align:center;";
 $headers .= 'display:none;' if $mobile;
 $headers .= '">';
 $headers .= "
  <a href=\"javascript:void(0);\" onmousedown=\"expand(1, 1);return false;\">Expand All</a>&nbsp;
  <a href=\"javascript:void(0);\" onmousedown=\"expand(0, 1);return false;\">Collapse All</a>&nbsp;
";
 $headers .= ($mobile ? '<br />': "<a href=\"javascript:void(0);\" onmousedown=\"slide();return false;\">sorted</a><br />") ;
  if ($WebIP{$ActWebSess}->{user} eq 'root') {
      $headers .= "<a href=\"./adminusers\" onclick=\"eraseCookie('lastAnchor');return true;\">manage users</a>";
  } else {
      $headers .= "<a href=\"./pwd\">Change Password</a>";
  }

 $headers .= "<a href=\".?mobile=0\">&nbsp;&nbsp;full GUI</a>" if $mobile;
 $headers .= "<a href=\".?mobile=1\">&nbsp;&nbsp;mobile view</a>" if ! $mobile;

 $headers .= "
<div class=\"rightButton\" style=\"text-align: center;\">
  <input type=\"button\" value=\"logout\" onclick=\"document.forms['SPAMBOXconfig'].theButtonLogout.value='  logout  ';eraseCookie('lastAnchor');window.location.href='./logout';return false;\" />\&nbsp;
  <a href=\"javascript:void(0);\" onclick=\"remember();return false;\" onmouseover=\"showhint('open the remember me window', this, event, '200px', '');return false;\"><img height=12 width=12 src=\"$wikiinfo\" /></a>&nbsp;
  <input type=\"button\" value=\"Apply\" onclick=\"document.forms['SPAMBOXconfig'].theButtonX.value='Apply Changes';document.forms['SPAMBOXconfig'].submit();WaitDiv();return false;\" />&nbsp;
";
 $headers .= "
  <a href=\"./fc\" target=\"_blank\" onmouseover=\"showhint('start the spambox file commander', this, event, '200px', '');return false;\"><img height=19 width=19 src=\"get?file=images/fc_main.png\" /></a>"
    if ($CanUseSPAMBOX_FC && &canUserDo($WebIP{$ActWebSess}->{user},'action','fc'));
 $headers .= "
</div>
<hr />
</div>
";
# the left main menu
 $headers .= "<div class=\"navMenu\"";
 if ($EnableFloatingMenu && ! $mobile) {
     $headers .= ' id="navMenu" style="position:absolute;margin:92px 0px 0px 0px;">';
 } else {
     my $hd = $mobile ? 'display:none;' : '';
     $headers .= ' id="navMenu" style="height:100%;overflow-y:hidden;position:absolute;margin:92px 0px 0px 0px;'.$hd.'"
     onmouseover="document.getElementById(\'navMenu\').style.overflowY=\'auto\';"
     onmouseout="document.getElementById(\'navMenu\').style.overflowY=\'hidden\';">';
 }

 $headers .= "
<script type=\"text/javascript\">
<!--
  setNavPosition();
// -->
</script>
";

 $headers .= "
  <div class=\"menuLevel1\"><a href=\"/\" onmousedown=\"setAnchor('delete');return false;\" /><img src=\"$plusIcon\" alt=\"plusicon\" /> Main</a><br /></div>\n<div>";
 my $counter = 0;
 for my $idx (0...$#ConfigArray) {
   my $c = $ConfigArray[$idx];
   if(@{$c} == 5) {
     $headers .= "</div>\n  <div class=\"menuLevel2\">\n  " .
#       ($mobile ? '' : "<a onmousedown=\"toggleDisp('$counter');setAnchor('delete');return false;\">") .
       ($mobile ? '' : "<a onmousedown=\"toggleDisp('$counter');return false;\">") .
       "<img id=\"treeIcon$counter\" src=\"$plusIcon\" alt=\"plusicon\" ". ($mobile ? "style=\"display:none \"" : '' ) . "/>" .
       ($mobile ? '' : ' '.$c->[4]).
       "</a>\n</div>\n<div id=\"treeElement$counter\" style=\"padding-left: 3px; display: block\">";
     $counter++;
   } else {
     $headers .= "\n    <div class=\"menuLevel3\"><a href=\"./#$c->[0]\" onmousedown=\"gotoAnchor('$c->[0]');return false;\">$c->[0]</a></div>"
       if (! $mobile && ! $hid && &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$c->[0]));
   }
 }
 $headers .= "</div>
<div class=\"menuLevel1\">$NavMenu</div>
<hr />
<div class=\"rightButton\" style=\"text-align: center;\">
  <input type=\"button\" value=\"  logout  \" onclick=\"document.forms['SPAMBOXconfig'].theButtonLogout.value='  logout  ';eraseCookie('lastAnchor');window.location.href='./logout';return false;\" />
</div>
<hr />
<div class=\"rightButton\" style=\"text-align: center;\">
  <input type=\"button\" value=\"Apply Changes\" onclick=\"document.forms['SPAMBOXconfig'].theButtonX.value='Apply Changes';document.forms['SPAMBOXconfig'].submit();WaitDiv();return false;\" />
</div>
<hr />
<div class=\"menuLevel2\">

	<a href=\"#\" onclick=\"return popFileEditor(\'/notes/confighistory.txt\',8); \"><img src=\"$noIcon\" alt=\"#\" /> Config Changes History</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'/notes/fc-history.txt\',8); \"><img src=\"$noIcon\" alt=\"#\" /> File Commander History</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'/notes/admininfo.txt\',8); \"><img src=\"$noIcon\" alt=\"#\" /> Admin Info Messages</a><br />
";
$headers .= "
	<a href=\"#\" onclick=\"return popFileEditor(\'/notes/configdefaults.txt\',8); \"><img src=\"$noIcon\" alt=\"#\" /> Non-Default Settings</a><br />
" if $WebIP{$ActWebSess}->{user} eq 'root';
$headers .= "
	<a href=\"#\" onclick=\"return popFileEditor(\'/notes/config.txt\',8);\"><img src=\"$noIcon\" alt=\"#\" /> Config Descriptions</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'rebuildrun.txt\',8);\"><img src=\"$noIcon\" alt=\"#\" /> Last SpamDB Rebuild</a><br />
";
$headers .= "
    <a href=\"./confgraph\" target=_blank><img src=\"$noIcon\" alt=\"#\" /> Bayes/HMM confidence</a><br />
" if &canUserDo($WebIP{$ActWebSess}->{user},'action','confgraph');

$headers .= "<hr />
	<hr />
	<span class=\"negative\"><center><b>internal Caches</b></center></span>
	<hr />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-AUTHErrors\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> AUTHErrors</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-DelayIPPB\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> DelayIPPB</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-IPNumTries\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> IPNumTries</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-IPNumTriesDuration\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> IPNumTriesDuration</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-IPNumTriesExpiration\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> IPNumTriesExp</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-SMTPdomainIP\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> SMTPdomainIP</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-SMTPdomainIPTries\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> SMTPdomainIPTries</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-SMTPdomainIPTriesExpiration\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> SMTPdomainIPTriesExp.</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-SSLfailed\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> SSLfailed</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-localTLSfailed\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> localTLSfailed</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-Stats\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> Stats</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-ScoreStats\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> ScoreStats</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-WhiteOrgList\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> WhiteOrgList</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-localFrequencyCache\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> localFrequencyCache</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-subjectFrequencyCache\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> subjectFrequencyCache</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-LDAPNotFound\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> LDAPNotFound</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-EmergencyBlock\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> EmergencyBlock</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-RFC822dom\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> RFC822dom</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-LastSchedRun\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> Scheduler History</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-T10StatI\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> TOP blocked IP\'s</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-T10StatS\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> TOP blocked senders</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-T10StatD\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> TOP blocked domains</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-T10StatR\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> TOP blocked recipients</a><br />
" if $rootlogin or &canUserDo($WebIP{$ActWebSess}->{user},'action','editinternals');

$headers .= "
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-DMARCpol\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> DMARC policies</a><br />
	<a href=\"#\" onclick=\"return popFileEditor(\'DB-DMARCrec\',\'1h\');\"><img src=\"$noIcon\" alt=\"#\" /> DMARC records</a>
" if (($rootlogin or &canUserDo($WebIP{$ActWebSess}->{user},'action','editinternals')) && $DoDKIM && $ValidateSPF);

$headers .= "<hr />
	<span style=\"font-weight: bold;\">SPAMBOX Version</span>: $version$modversion<br />
	".($codename?"<span style=\"font-weight: bold;\">code name</span>: $codename<br />":'')."
	<span style=\"font-weight: bold;\">Current PID</span>: $mypid<br />
	<span style=\"font-weight: bold;\">Started</span>: $starttime<br />
</div>
<hr />
";

$headers .= "</div>
<script type=\"text/javascript\">
  <!--
  ";
 if (! $mobile && $EnableFloatingMenu) {
     $headers .= "document.getElementById('navMenu').style.height=ClientSize('h') + 'px';";
     $headers .= 'JSFX_FloatDiv("navMenu",2,85,2,-2,2,99999).flt();';
     $headers .= 'JSFX_FloatDiv("topnav",2,85,2,-2,2,99999).flt();';
     $headers .= '
  expand(0,0);
';
 } else {
     $headers .= '
  expand(0,0);
';
     $headers .= "document.getElementById('navMenu').style.height=ClientSize('h') + 'px';";
 }

 my @regerr = keys %RegexError;
 $headers .= "alert('found regular expression errors in : @regerr')" if @regerr;

 $headers .= '
  // -->
  </script>
  ';
  
    $footers = "
<div class=\"contentFoot\">
<a href=\"remotesupport\" target=\"_blank\">Remote Support</a> |
<a href=\"github\">github</a> |

 <a id=\"printLink\" href=\"javascript:void(processPrint());\">Print Config/Screen</a>
</div>";
if ($mobile) {
    $footers .= "
<script type=\"text/javascript\">
<!--
  showLeftMenu();showLeftMenu();
  document.getElementById('printLink').innerHTML = '&nbsp;';
// -->
</script>
";
} else {
    $footers .= "
<script type=\"text/javascript\">
<!--
    if (document.getElementById(\"mainhints\") != null) {
        document.getElementById('printLink').innerHTML = 'Print the Manual';
    } else {
        document.getElementById('printLink').innerHTML = 'Print the Screen';
    }
// -->
</script>
";
}

    $kudos = '
<div class="kudos">
 <a href="http://spambox.cvs.sourceforge.net" rel="external" target="_blank">
 <img src="get?file=images/village.gif" alt="Development" height="31" width="31" /></a>
 <a href="http://sourceforge.net" rel="external" target="_blank">
 <img src="get?file=images/sourceforge-logo.gif" alt="SourceForge" height="31" width="88" /></a>
 <a href="http://opensource.org" rel="external" target="_blank">
 <img src="get?file=images/opensource-logo.gif" alt="Open Source" height="31" width="88" /></a>
</div>
';
}
