/* ASSP file commander Javascript VERSION 1.05 */

var selectFileLeft  = new Array();
var selectFileRight = new Array();
var selectDirLeft   = new Array();
var selectDirRight  = new Array();

function delCRLF(str) {
    str.replace(/\r\n/g , '');
    return str;
}

//  base64.encode(string)
//  base64.decode(string)
var base64 = (function() {
    "use strict";

    var _keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    var _utf8_encode = function (string) {

        var utftext = "", c, n;

        string = string.replace(/\r\n/g,"\n");

        for (n = 0; n < string.length; n++) {

            c = string.charCodeAt(n);

            if (c < 128) {

                utftext += String.fromCharCode(c);

            } else if((c > 127) && (c < 2048)) {

                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);

            } else {

                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);

            }

        }

        return utftext;
    };

    var _utf8_decode = function (utftext) {
        var string = "", i = 0, c = 0, c1 = 0, c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {

                string += String.fromCharCode(c);
                i++;

            } else if((c > 191) && (c < 224)) {

                c1 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c1 & 63));
                i += 2;

            } else {

                c1 = utftext.charCodeAt(i+1);
                c2 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c1 & 63) << 6) | (c2 & 63));
                i += 3;

            }

        }

        return string;
    };

    var encode = function (input) {
        var output = "", chr1, chr2, chr3, enc1, enc2, enc3, enc4, i = 0;

        input = _utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output += _keyStr.charAt(enc1);
            output += _keyStr.charAt(enc2);
            output += _keyStr.charAt(enc3);
            output += _keyStr.charAt(enc4);

        }

        return output;
    };

    var decode = function (input) {
        var output = "", chr1, chr2, chr3, enc1, enc2, enc3, enc4, i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = _keyStr.indexOf(input.charAt(i++));
            enc2 = _keyStr.indexOf(input.charAt(i++));
            enc3 = _keyStr.indexOf(input.charAt(i++));
            enc4 = _keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output += String.fromCharCode(chr1);

            if (enc3 !== 64) {
                output += String.fromCharCode(chr2);
            }
            if (enc4 !== 64) {
                output += String.fromCharCode(chr3);
            }

        }

        return _utf8_decode(output);
    };

    return {
        'encode': encode,
        'decode': decode
    };
}());

function endsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function popFileEditor(filename,note) {
  WaitDiv();
  var height = (note == 0) ? 500 : (note == 'm') ? 580 : 550;
  var newwindow=window.open(
    'edit?file='+filename+'&note='+note,
    'FileEditor',
    'width=720,height='+height+',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes'
  );
  if (window.focus) {newwindow.focus()}
  WaitDivDel();
  return false;
}

function leftm(event) {
    if ('buttons' in event) {
        return event.buttons === 1;
    } else if ('which' in event) {
        return event.which === 1;
    } else {
        return event.button === 1;
    }
}

function keypressed (Ereignis) {
  if (!Ereignis)
    Ereignis = window.event;
//  if (Ereignis.altKey)
//    alert("Eine Taste plus Alt-Taste wurde gedrückt!");
//  if (Ereignis.ctrlKey)
//    alert("Eine Taste plus Steuerung-Taste wurde gedrückt!");
//  if (Ereignis.shiftKey)
//    alert("Eine Taste plus Umschalt-Taste wurde gedrückt!");
  return Ereignis.keyCode;

// 45 - insert
// 46 - delete
// 13 - enter
// 32 - space
// 112 - 123 - F1-F12
}

function fTP(Num){
    var rx=  /(\d+)(\d{3})/;
    return String(Num).replace(/^\d+/, function(w){
        while(rx.test(w)){
            w= w.replace(rx, '$1.$2');
        }
        return w;
    });
}

function ufTP(Num) {
            var rgx = /\./;  
            while (rgx.test(Num)) { 
                Num = Num.replace(rgx, '');
            }
            return Num;
}

function hasClass(ele, cls) {
    return ele.className.match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
}

function addClass(ele, cls) {
    if (!this.hasClass(ele, cls)) ele.className += cls;
}

function removeClass(ele, cls) {
    var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
    ele.className = ele.className.replace(reg, '');
}

function toggleClass(ele, cls1, cls2){
    if(hasClass(ele, cls1)){
        removeClass(ele, cls1);
        addClass(ele, cls2);
    }else{
        removeClass(ele, cls2);
        addClass(ele, cls1);
    }
}

function toggleColSel(self,col) {
    var show = self.checked  ? 'table-cell' : 'none';
    var cols = document.getElementsByTagName('td');
	for (var i=0; cols.item(i); i++) {
		if (cols[i].getAttribute("name") == col) {
            cols[i].style.display = show;
        }
	}
    cols = document.getElementsByTagName('th');
	for (var i=0; cols.item(i); i++) {
		if (cols[i].getAttribute("name") == col) {
            cols[i].style.display = show;
        }
	}
    cols = document.getElementsByTagName('col');
	for (var i=0; cols.item(i); i++) {
		if (cols[i].getAttribute("name") == col) {
            cols[i].style.display = show;
        }
	}
}

function setFilter(site) {
    var loc = window.location.href;
    var sel = prompt("filter: enter the display filter (eg. *.txt) wildcards are(* and ?)","*");
    sel = delCRLF(sel);
    if (sel==null || sel=="") return;
    var re = new RegExp('([&?]filter' + site + '=)[^&]*');
    loc = loc.replace(re , '$1' + sel);
    if(! re.test(loc)) loc = '?filter' + site + '=' + sel;
    window.location.href = loc;
}

function delFilter(site) {
    var loc = window.location.href;
    var re = new RegExp('([&?]filter' + site + '=)[^&]*');
    loc = loc.replace(re , '$1' + '*');
    if(! re.test(loc)) loc = '?filter' + site + '=*';
    window.location.href = loc;
}

function doSelect(site) {
    var re = prompt("select: enter the file type (eg. *.txt) wildcards are(* and ?)","*");
    re = delCRLF(re);
    re = re.replace(/\./g , '\\.');
    re = re.replace(/\*/g , '.*');
    re = re.replace(/\?/g , '.');
    re = '^'+re+'$';
    re = new RegExp(re,'i');
    var count = 1;
    var id;
    while(id = document.getElementById('rowd' + site + count)) {
        var name = id.getAttribute("name");
        name = name.match(/([^\/]*\.?[^\/]+)$/);
        if (hasClass(id, 'trow') && re.test(name[0])) {
            if (site === 'l') {
                toggleItemleft (id,id.getAttribute("name"),'trow','dir',1);
            } else {
                toggleItemright (id,id.getAttribute("name"),'trow','dir',1);
            }
        }
        count++;
    }
    count = 1;
    while(id = document.getElementById('rowf' + site + count)) {
        var name = id.getAttribute("name").split(",");
        var fname = name[0].match(/([^\/]*\.?[^\/]+)$/);
        if (hasClass(id, 'trow') && re.test(fname[0])) {
            if (site === 'l') {
                toggleItemleft (id,name[0],'trow','file',parseInt(name[1]));
            } else {
                toggleItemright (id,name[0],'trow','file',parseInt(name[1]));
            }
        }
        count++;
    }
}

function unSelect(site) {
    var re = prompt("unselect: enter the file type (eg. *.txt) - supported wildcards are(* and ?)","*");
    re = delCRLF(re);
    re = re.replace(/\./g , '\\.');
    re = re.replace(/\*/g , '.*');
    re = re.replace(/\?/g , '.');
    re = '^'+re+'$';
    re = new RegExp(re,'i');
    var count = 1;
    var id;
    while(id = document.getElementById('rowd' + site + count)) {
        var name = id.getAttribute("name");
        name = name.match(/([^\/]*\.?[^\/]+)$/);
        if (hasClass(id, 'strow') && re.test(name[0])) {
            if (site === 'l') {
                toggleItemleft (id,id.getAttribute("name"),'trow','dir',1);
            } else {
                toggleItemright (id,id.getAttribute("name"),'trow','dir',1);
            }
        }
        count++;
    }
    count = 1;
    while(id = document.getElementById('rowf' + site + count)) {
        var name = id.getAttribute("name").split(",");
        var fname = name[0].match(/([^\/]*\.?[^\/]+)$/);
        if (hasClass(id, 'strow') && re.test(fname[0])) {
            if (site === 'l') {
                toggleItemleft (id,name[0],'trow','file',parseInt(name[1]));
            } else {
                toggleItemright (id,name[0],'trow','file',parseInt(name[1]));
            }
        }
        count++;
    }
}

function toggleSelect(site) {
    var count = 1;
    var id;
    while(id = document.getElementById('rowd' + site + count)) {
        if (site === 'l') {
            toggleItemleft (id,id.getAttribute("name"),'trow','dir',1);
        } else {
            toggleItemright (id,id.getAttribute("name"),'trow','dir',1);
        }
        count++;
    }
    count = 1;
    while(id = document.getElementById('rowf' + site + count)) {
        var name = id.getAttribute("name").split(",");
        if (site === 'l') {
            toggleItemleft (id,name[0],'trow','file',parseInt(name[1]));
        } else {
            toggleItemright (id,name[0],'trow','file',parseInt(name[1]));
        }
        count++;
    }
}

function toggleItemleft (self,item,type,what,size) {
    toggleClass(self,type,'s'+type);
    var how = 0;
    if (what === 'file') {
        if( selectFileLeft[item] === undefined ) selectFileLeft[item] = 0;
        selectFileLeft[item] = selectFileLeft[item]===1 ? 0 : 1;
        how = selectFileLeft[item];
    } else {
        if( selectDirLeft[item] === undefined ) selectDirLeft[item] = 0;
        selectDirLeft[item] = selectDirLeft[item]===1 ? 0 : 1;
        how = selectDirLeft[item];
    }
    if (how===1) {
        if (what === 'file') {
            var nsize = parseInt(ufTP(document.getElementById("filesizel").innerHTML))+size;
            document.getElementById("filesizel").innerHTML = fTP(nsize);
            document.getElementById("filecountl").innerHTML = parseInt(document.getElementById("filecountl").innerHTML)+1;
        } else {
            document.getElementById("dircountl").innerHTML = parseInt(document.getElementById("dircountl").innerHTML)+1;
        }
    } else {
        if (what === 'file') {
            var nsize = parseInt(ufTP(document.getElementById("filesizel").innerHTML))-size;
            document.getElementById("filesizel").innerHTML = fTP(nsize);
            document.getElementById("filecountl").innerHTML = parseInt(document.getElementById("filecountl").innerHTML)-1;
        } else {
            document.getElementById("dircountl").innerHTML = parseInt(document.getElementById("dircountl").innerHTML)-1;
        }
    }
    return false;
}

function toggleItemright (self,item,type,what,size) {
    toggleClass(self,type,'s'+type);
    var how = 0;
    if (what === 'file') {
        if( selectFileRight[item] === undefined ) selectFileRight[item] = 0;
        selectFileRight[item] = selectFileRight[item]===1 ? 0 : 1;
        how = selectFileRight[item];
    } else {
        if( selectDirRight[item] === undefined ) selectDirRight[item] = 0;
        selectDirRight[item] = selectDirRight[item]===1 ? 0 : 1;
        how = selectDirRight[item];
    }
    if (how===1) {
        if (what === 'file') {
            var nsize = parseInt(ufTP(document.getElementById("filesizer").innerHTML))+size;
            document.getElementById("filesizer").innerHTML = fTP(nsize);
            document.getElementById("filecountr").innerHTML = parseInt(document.getElementById("filecountr").innerHTML)+1;
        } else {
            document.getElementById("dircountr").innerHTML = parseInt(document.getElementById("dircountr").innerHTML)+1;
        }
    } else {
        if (what === 'file') {
            var nsize = parseInt(ufTP(document.getElementById("filesizer").innerHTML))-size;
            document.getElementById("filesizer").innerHTML = fTP(nsize);
            document.getElementById("filecountr").innerHTML = parseInt(document.getElementById("filecountr").innerHTML)-1;
        } else {
            document.getElementById("dircountr").innerHTML = parseInt(document.getElementById("dircountr").innerHTML)-1;
        }
    }
    return false;
}

function showLog() {
    popFileEditor('notes/fc-history.txt',8);
}

function openConfig() {
    var newwindow=window.open(
      './',
      'ASSP Configuration',
      'height=' + screen.height + ',width=' + screen.width + ',resizable=yes,scrollbars=yes,toolbar=yes,menubar=yes,location=yes'
    );
    if (window.focus) {newwindow.focus()}
}

function actionView() {
    var key;
    var any = 0;
 
    for (key in selectFileLeft) {
	    any |= selectFileLeft[key];
	    if (selectFileLeft[key] === 1) popFileEditor(key,8);
    }
    for (key in selectFileRight) {
	    any |= selectFileRight[key];
	    if (selectFileRight[key] === 1) popFileEditor(key,8);
    }
    if (any===0) alert('nothing selected');
}

function actionEdit() {
    var key;
    var any = 0;
 
    for (key in selectFileLeft) {
	    any |= selectFileLeft[key];
	    
	    if (selectFileLeft[key] === 1) {
	        var act = 1;
	        if (endsWith(key,mailext) == true) act = 'm';
	        popFileEditor(key,act);
	    }    
    }
    for (key in selectFileRight) {
	    any |= selectFileRight[key];
	    if (selectFileRight[key] === 1) {
	        var act = 1;
	        if (endsWith(key,mailext) == true) act = 'm';
	        popFileEditor(key,act);
	    }    
    }
    if (any===0) alert('nothing selected');
}

function actionCopy(from,to) {
    var key;
    if (from === to) {
        alert('can not move in to the same folder!');
        return;
    }

    var any = 0;
    for (key in selectFileLeft ) { any += selectFileLeft[key]; }
    for (key in selectFileRight) { any += selectFileRight[key];}
    for (key in selectDirLeft  ) { any += selectDirLeft[key];  }
    for (key in selectDirRight ) { any += selectDirRight[key]; }
    if (any === 0) { 
        alert('nothing selected'); 
        return; 
    }

    var conf = confirm("Are you sure you want to copy the "+any+" selected files and folders from "+from+" to "+to+" and reverse?");
    if(conf == false) return;
    var cmd = '';
    for (key in selectFileLeft) {
	    if (selectFileLeft[key] === 1)  cmd += 'copy('+key+','+to+');';
    }
    for (key in selectFileRight) {
	    if (selectFileRight[key] === 1) cmd += 'copy('+key+','+from+');';
    }

    for (key in selectDirLeft) {
	    if (selectDirLeft[key] === 1) cmd += 'copy('+key+','+to+');';
    }
    for (key in selectDirRight) {
	    if (selectDirRight[key] === 1) cmd += 'copy('+key+','+from+');';
    }
    
    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionMove(from,to) {
    var key;
    if (from === to) {
        alert('can not move in to the same folder!');
        return;
    }

    var any = 0;
    for (key in selectFileLeft ) { any += selectFileLeft[key]; }
    for (key in selectFileRight) { any += selectFileRight[key];}
    for (key in selectDirLeft  ) { any += selectDirLeft[key];  }
    for (key in selectDirRight ) { any += selectDirRight[key]; }
    if (any === 0) { 
        alert('nothing selected'); 
        return; 
    }

    var conf = confirm("Are you sure you want to move the "+any+" selected files and folders from "+from+" to "+to+" and reverse?");
    if(conf == false) return;
    var cmd = '';
    for (key in selectFileLeft) {
	    if (selectFileLeft[key] === 1)  cmd += 'move('+key+','+to+');';
    }
    for (key in selectFileRight) {
	    if (selectFileRight[key] === 1) cmd += 'move('+key+','+from+');';
    }

    for (key in selectDirLeft) {
	    if (selectDirLeft[key] === 1) cmd += 'move('+key+','+to+');';
    }
    for (key in selectDirRight) {
	    if (selectDirRight[key] === 1) cmd += 'move('+key+','+from+');';
    }
    
    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionNewDir(flr) {
    var folder = prompt("Please enter the name of the new folder in "+flr+" :" , "new folder");
    folder = delCRLF(folder);
    var cmd;
    if (folder!=null && folder!="") {
        cmd = 'create('+flr+'/'+folder+');';
    } else {
        return;
    }

    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionDelete() {
    var key;
    var any = 0;
    for (key in selectFileLeft ) { any += selectFileLeft[key]; }
    for (key in selectFileRight) { any += selectFileRight[key];}
    for (key in selectDirLeft  ) { any += selectDirLeft[key];  }
    for (key in selectDirRight ) { any += selectDirRight[key]; }
    if (any === 0) { 
        alert('nothing selected'); 
        return; 
    }

    var conf = confirm("Are you sure you want to delete the "+any+" selected files and folders on both sites?");
    if(conf == false) return;
    var cmd = '';
    for (key in selectFileLeft) {
	    if (selectFileLeft[key] === 1)  cmd += 'delete('+key+');';
    }
    for (key in selectFileRight) {
	    if (selectFileRight[key] === 1) cmd += 'delete('+key+');';
    }

    for (key in selectDirLeft) {
	    if (selectDirLeft[key] === 1) cmd += 'delete('+key+');';
    }
    for (key in selectDirRight) {
	    if (selectDirRight[key] === 1) cmd += 'delete('+key+');';
    }

    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionRename() {
    var key;
    var any = 0;

    for (key in selectFileLeft ) { any += selectFileLeft[key]; }
    for (key in selectFileRight) { any += selectFileRight[key];}
    for (key in selectDirLeft  ) { any += selectDirLeft[key];  }
    for (key in selectDirRight ) { any += selectDirRight[key]; }
    if (any === 0) {
        alert('nothing selected');
        return;
    }

    var newname = prompt("Please enter the new name pattern - supported wildcards are(* and ?)","");
    newname = delCRLF(newname);
    if(newname == false || newname == null || newname === '') return;

    newname.replace(/^\s+|\s+$/g,'');
    var re = /(\?\*|\*\?|\*\*|^\*$|^\*\.\*$)/;
    if (re.test(newname)) {
        alert("patter is wrong - contains ?* or *? or ** or a single * or *.*");
        return;
    }
    var cmd = '';
    for (key in selectFileLeft) {
	    if (selectFileLeft[key] === 1)  cmd += 'rename('+key+','+newname+');';
    }
    for (key in selectFileRight) {
	    if (selectFileRight[key] === 1) cmd += 'rename('+key+','+newname+');';
    }

    for (key in selectDirLeft) {
	    if (selectDirLeft[key] === 1) cmd += 'rename('+key+','+newname+');';
    }
    for (key in selectDirRight) {
	    if (selectDirRight[key] === 1) cmd += 'rename('+key+','+newname+');';
    }

    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionAnalyze() {
    var key;
    var any = 0;
    var count = 0
    for (key in selectFileLeft) {
        if (endsWith(key,mailext) != true) next;
        if (count > 2) break;
	    any |= selectFileLeft[key];
	    if (selectFileLeft[key] === 1) {
            newwindow=window.open(
              'analyze?file='+key,
              'ASSP Anlayze '+key,
              'toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes'
            );
            count++;
        }
    }
    for (key in selectFileRight) {
        if (endsWith(key,mailext) != true) next;
        if (count > 2) break;
	    any |= selectFileRight[key];
	    if (selectFileRight[key] === 1) {
            newwindow=window.open(
              'analyze?file='+key,
              'ASSP Anlayze',
              ''
            );
	    }
    }
    if (any===0) alert('nothing selected');
    if (count > 3) alert('max 3 files could be selected for analyze');
}

function actionZip(pathl,pathr) {
    var key;
    var any = 0;

    for (key in selectFileLeft ) { any += selectFileLeft[key]; }
    for (key in selectDirLeft  ) { any += selectDirLeft[key];  }
    if (any === 0) {
        alert('nothing selected on the left site');
        return;
    }

    var newname = prompt("Please enter the full path and name of the compressed file to create. The used compression methode is selected by the file extension ( gz , bz2 , tgz , tbz , tar.gz , tar.bz2, zip) ",pathr+'/');
    newname = delCRLF(newname);
    if(newname == false || newname == null || newname === '') return;

    newname.replace(/^\s+|\s+$/g,'');
    var re = /\.(gz|bz2|tgz|tbz|tar\.gz|tar\.bz2|zip)$/;
    if (! re.test(newname)) {
        alert("wrong filename - "+newname+" no valid compression extension found");
        return;
    }
    if (newname.substr(0,asspbase.length) != asspbase) {
        alert("target filename - "+newname+" is not in an assp folder");
        return;
    }

    var cmd = 'zip('+newname+','+pathl;
    for (key in selectFileLeft) {
	    if (selectFileLeft[key] === 1)  cmd += ','+key;
    }
    for (key in selectDirLeft) {
	    if (selectDirLeft[key] === 1) cmd += ','+key;
    }
    cmd += ');';
    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function unZip(file,site) {
    var cmd = 'unzip('+file+','+site+');';
    
    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function actionDownload() {
    var key;
    var any = 0;
    var filename;

    for (key in selectFileLeft ) {
        any += selectFileLeft[key];
        if (any > 0) {
            filename = key;
            break;
        }
    }
    if (any === 0) {
        alert('no file selected on the left site');
        return;
    }
    var newwindow=window.open(
      'get?file='+filename,
      'Download File',
      'width=100,height=50,overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes'
    );
    if (window.focus) {newwindow.focus()}
}

function actionUpload(folder) {
    var newwindow=window.open(
      'fc?cmd=upload('+folder+');',
      'Upload File',
      'width=380,height=230,overflow=scroll,toolbar=no,menubar=no,location=no,personalbar=no,scrollbars=yes,status=no,directories=no,resizable=yes'
    );
    if (window.focus) {newwindow.focus()}
}

function runPPM(file) {
    var cmd = 'runPPM('+file+',ppm);';

    var conf = confirm("Are you sure you want to install the modules associated with the package "+file+" via ppm (Perl package Manager) ?");
    if(conf == false) return;
    document.getElementById("cmd").value = cmd;
    document.getElementById("TCCMD").submit();
    WaitDiv();
}

function WaitDiv() {
	document.getElementById('wait').style.display = 'block';
}

function WaitDivDel() {
	document.getElementById('wait').style.display = 'none';
}

/* document.onkeypress = keypressed; */


//
// Resizable Table Columns.
//  version: 1.0
//
// (c) 2006, bz
//
// 25.12.2006:  first working prototype
// 26.12.2006:  now works in IE as well but not in Opera (Opera is @#$%!)
// 27.12.2006:  changed initialization, now just make class='resizable' in table and load script
//
function preventEvent(e) {
	var ev = e || window.event;
	if (ev.preventDefault) ev.preventDefault();
	else ev.returnValue = false;
	if (ev.stopPropagation)
		ev.stopPropagation();
	return false;
}

function getStyle(x, styleProp) {
	if (x.currentStyle)
		var y = x.currentStyle[styleProp];
	else if (window.getComputedStyle)
		var y = document.defaultView.getComputedStyle(x,null).getPropertyValue(styleProp);
	return y;
}

function getWidth(x) {
	if (x.currentStyle)
		// in IE
		var y = x.clientWidth - parseInt(x.currentStyle["paddingLeft"]) - parseInt(x.currentStyle["paddingRight"]);
		// for IE5: var y = x.offsetWidth;
	else if (window.getComputedStyle)
		// in Gecko
		var y = document.defaultView.getComputedStyle(x,null).getPropertyValue("width");
	return y || 0;
}

function setCookie (name, value, expires, path, domain, secure) {
	document.cookie = name + "=" + escape(value) +
		((expires) ? "; expires=" + expires : "") +
		((path) ? "; path=" + path : "") +
		((domain) ? "; domain=" + domain : "") +
		((secure) ? "; secure" : "");
}

function getCookie(name) {
	var cookie = " " + document.cookie;
	var search = " " + name + "=";
	var setStr = null;
	var offset = 0;
	var end = 0;
	if (cookie.length > 0) {
		offset = cookie.indexOf(search);
		if (offset != -1) {
			offset += search.length;
			end = cookie.indexOf(";", offset)
			if (end == -1) {
				end = cookie.length;
			}
			setStr = unescape(cookie.substring(offset, end));
		}
	}
	return(setStr);
}
// main class prototype
function ColumnResize(table) {
	if (table.tagName != 'TABLE') return;

	this.id = table.id;

	// ============================================================
	// private data
	var self = this;

	var dragColumns  = table.rows[0].cells; // first row columns, used for changing of width
	if (!dragColumns) return; // return if no table exists or no one row exists

	var dragColumnNo; // current dragging column
	var dragX;        // last event X mouse coordinate

	var saveOnmouseup;   // save document onmouseup event handler
	var saveOnmousemove; // save document onmousemove event handler
	var saveBodyCursor;  // save body cursor property

	// ============================================================
	// methods

	// ============================================================
	// do changes columns widths
	// returns true if success and false otherwise
	this.changeColumnWidth = function(no, w) {
		if (!dragColumns) return false;

		if (no < 0) return false;
		if (dragColumns.length < no) return false;

        var name = table.getAttribute("name");
        var id = table.getAttribute("id");
        var tables = document.getElementsByTagName('table');
        var dragDataColumns
        for (var i=0; tables.item(i); i++) {
            if (tables[i].className.match(/resizable/) && name == tables[i].getAttribute("name") && id != tables[i].getAttribute("id")) {
                dragDataColumns = tables[i].rows[0].cells;
    		}
    	}

		if (parseInt(dragColumns[no].style.width) <= -w) return false;
		if (parseInt(dragDataColumns[no].style.width) <= -w) return false;
		if (dragColumns[no+1] && parseInt(dragColumns[no+1].style.width) <= w) return false;
		if (dragDataColumns[no+1] && parseInt(dragDataColumns[no+1].style.width) <= w) return false;

		dragColumns[no].style.width = parseInt(dragColumns[no].style.width) + w +'px';
		dragDataColumns[no].style.width = dragColumns[no].style.width;
		if (dragColumns[no+1]) {
			dragColumns[no+1].style.width = parseInt(dragColumns[no+1].style.width) - w + 'px';
			dragDataColumns[no+1].style.width = dragColumns[no+1].style.width;
        }

		return true;
	}

	// ============================================================
	// do drag column width
	this.columnDrag = function(e) {
		var e = e || window.event;
		var X = e.clientX || e.pageX;
		if (!self.changeColumnWidth(dragColumnNo, X-dragX)) {
			// stop drag!
			self.stopColumnDrag(e);
		}

		dragX = X;
		// prevent other event handling
		preventEvent(e);
		return false;
	}

	// ============================================================
	// stops column dragging
	this.stopColumnDrag = function(e) {
		var e = e || window.event;
		if (!dragColumns) return;

		// restore handlers & cursor
		document.onmouseup  = saveOnmouseup;
		document.onmousemove = saveOnmousemove;
		document.body.style.cursor = saveBodyCursor;

		// remember columns widths in cookies for server side
		var colWidth = '';
		var separator = '';
		for (var i=0; i<dragColumns.length; i++) {
			colWidth += separator + parseInt( getWidth(dragColumns[i]) );
			separator = '+';
		}
		var expire = new Date();
		expire.setDate(expire.getDate() + 365); // year
		document.cookie = self.id + '-width=' + colWidth +
			'; expires=' + expire.toGMTString();

		preventEvent(e);
	}

	// ============================================================
	// init data and start dragging
	this.startColumnDrag = function(e) {
		var e = e || window.event;

		// if not first button was clicked
		//if (e.button != 0) return;

		// remember dragging object
		dragColumnNo = (e.target || e.srcElement).parentNode.parentNode.cellIndex;
		dragX = e.clientX || e.pageX;

		// set up current columns widths in their particular attributes
		// do it in two steps to avoid jumps on page!
		var colWidth = new Array();
		for (var i=0; i<dragColumns.length; i++)
			colWidth[i] = parseInt( getWidth(dragColumns[i]) );
		for (var i=0; i<dragColumns.length; i++) {
			dragColumns[i].width = ""; // for sure
			dragColumns[i].style.width = colWidth[i] + "px";
		}

		saveOnmouseup       = document.onmouseup;
		document.onmouseup  = self.stopColumnDrag;

		saveBodyCursor             = document.body.style.cursor;
		document.body.style.cursor = 'w-resize';

		// fire!
		saveOnmousemove      = document.onmousemove;
		document.onmousemove = self.columnDrag;

		preventEvent(e);
	}

	// prepare table header to be draggable
	// it runs during class creation
	for (var i=0; i<dragColumns.length; i++) {
		dragColumns[i].innerHTML = "<div style='position:relative;height:100%;width:100%'>"+
			"<div style='"+
			"position:absolute;height:100%;width:5px;margin-right:-5px;"+
			"left:100%;top:0px;cursor:w-resize;z-index:10;'>"+
			"</div>"+
			dragColumns[i].innerHTML+
			"</div>";
			// BUGBUG: calculate real border width instead of 5px!!!
		dragColumns[i].firstChild.firstChild.onmousedown = this.startColumnDrag;
	}
}

// select all tables and make resizable those that have 'resizable' class
var resizableTables = new Array();
function ResizableColumns() {

	var tables = document.getElementsByTagName('table');
	for (var i=0; tables.item(i); i++) {
		if (tables[i].className.match(/resizable/)) {
			// generate id
			if (!tables[i].id) tables[i].id = 'table'+(i+1);
			// make table resizable
			resizableTables[resizableTables.length] = new ColumnResize(tables[i]);
		}
	}
//	alert(resizableTables.length + ' tables was added.');
}
// init tables
/*
if (document.addEventListener)
	document.addEventListener("onload", ResizableColumns, false);
else if (window.attachEvent)
	window.attachEvent("onload", ResizableColumns);
*/
try {
    if (document.addEventListener)
    	document.addEventListener("onload", ResizableColumns, false);
    else if (window.attachEvent)
    	window.attachEvent("onload", ResizableColumns);
} catch(e) {
}

try {
	window.addEventListener('load', ResizableColumns, false);
} catch(e) {
    try {
        window.onload = ResizableColumns;
    } catch(e) {
    }
}

function adjustTableCols() {
	var tables = document.getElementsByTagName('table');
	for (var i=0; tables.item(i); i++) {
		if (tables[i].className.match(/resizable/) && tables[i].className.match(/tbody/)) {
            for (var j=0; tables.item(j); j++) {
                if (tables[j].className.match(/thead/) && tables[j].getAttribute("name") == tables[j].getAttribute("name")) {
                    var dragDataColumns = tables[i].rows[0].cells;
                    var dragColumns = tables[j].rows[0].cells;
                    for (var t=0; t < dragDataColumns.length; t++) {
                        dragColumns[t].style.width = parseInt(dragDataColumns[t].clientWidth)+'px';
                    }
                }
            }
        }
	}
}
//document.body.onload = ResizableColumns;

//============================================================
//
// Usage. In your html code just include the follow:
//
//============================================================
// <table id='objectId'>
// ...
// </table>
// < script >
// var xxx = new ColumnDrag( 'objectId' );
// < / script >
//============================================================
//
// NB! spaces was used to prevent browser interpret it!
//
//============================================================

