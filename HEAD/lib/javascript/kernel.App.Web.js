function SwitchExt()
{
   var blk=window.document.getElementById("ext");
   var res=window.document.getElementById("result");
   if (blk.style.display=="none" || blk.style.display==""){
      blk.style.display="block";
      blk.style.visibillity="visible";
   }
   else{
      blk.style.display="none";
      blk.style.visibillity="hidden";
   }
   return;
}


function DoViewEditor()
{
   document.forms[0].action='Result';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlViewEditor';
   document.forms[0].submit();

   return;
}

function DoAnalytic(f)
{
   DisplayLoading(frames['Result'].document);
   document.forms[0].action=f;
   document.forms[0].target="Result";
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   document.forms[0].submit();

   return;
}

function DoBookmark()
{
   if (showPopWin){
      showPopWin('Bookmark',460,250);
      document.forms[0].action='Bookmark';
      document.forms[0].target='popupFrame';
      document.forms[0].submit();
   }
   else{
      alert("Sorry, method not available");
   }
}

function DoPrint()
{
   var DirectView;
   DirectView=window.frames['Result'].document.getElementById("DirectView");
   
   if (DirectView){
      alert("Print of ViewSelect isn't supported");
      //DirectView.focus();
      //DirectView.print();
   }
   else{
      window.frames['Result'].focus();
      window.frames['Result'].print();
   }
}

function DoResetMask(msg)
{
   if (confirm(msg)){
      for(var i = 0; i < document.forms.length; i++) {
         for(var e = 0; e < document.forms[i].length; e++){
            if(document.forms[i].elements[e].tagName == "INPUT" &&
               document.forms[i].elements[e].type   == "text") {
               document.forms[i].elements[e].value="";
            }
         }
      }
   }
}

function DisplayLoading(w)
{
   w.close();
   w.open();
   w.write("<html>");
   w.write("<body bgcolor=\"#ffffff\" style=\"cursor:wait\">");
   w.write("<table border=0 width=100% height=100%>");
   w.write("<tr><td align=center><font face=\"Arial,Helvetica\">Loading ...");
   w.write("</td></tr>");
   w.write("</table>");
   w.write("</body>");
   w.write("</html>");
   w.close();
}

function nativeDoSearch()
{
   var d;
   document.forms[0].action='Result';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   DisplayLoading(frames['Result'].document);
   document.forms[0].submit();
   return;
}



function DoRemoteSearch(action,target,FormatAs,CurrentView,DisplayLoadingSet)
{
   var d;
   if (action){
      document.forms[0].action=action;
      document.forms[0].action="Result";
   }
   if (target){
      document.forms[0].target=target;
   }
   if (FormatAs){
      document.forms[0].elements['FormatAs'].value=FormatAs;
   }
   if (CurrentView){
      document.forms[0].elements['CurrentView'].value=CurrentView;
   }
   if (DisplayLoadingSet){
      DisplayLoading(frames['Result'].document);
   }
   document.forms[0].submit();
   return;
}



function DoNew()
{
   var d;
   document.forms[0].action='New';
   document.forms[0].target='_self';
   document.forms[0].submit();
   return;
}

function DoNewWin()
{
   var d;

   openwin("New","_blank","height=480,width=600,toolbar=no,status=no,"+
           "resizable=yes,scrollbars=auto");
}

function SaveDefaults()
{
   document.forms[0].action='SaveDefaults';
   document.forms[0].target='_self';
   document.forms[0].submit();

   return;
}
