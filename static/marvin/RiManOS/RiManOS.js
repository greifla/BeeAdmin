var W5Base=createConfig({ useUTF8:false, mode:'auth',transfer:'JSON' });



$(document).on( "mobileinit", function() {
   // ----------------------------------------------------
   // configure Loading box
   $.mobile.loader.prototype.options.text = "loading ...";
   $.mobile.loader.prototype.options.textVisible = true;
   $.mobile.loader.prototype.options.theme = "b";
   $.mobile.loader.prototype.options.html = "";
   // ----------------------------------------------------
});



var app={};

function load_mgmtitemgroup_scenario(nextCall)
{
   loadList('itil::mgmtitemgroup','name,id,applications',function(res){
         app.mgmtitemgroup={rec:[],id:{}};
         for(c=0;c<res.length;c++){
            if (res[c].applications.length){ //only top lists with applications
               app.mgmtitemgroup.id[String(res[c].id)]=res[c];
               app.mgmtitemgroup.rec.push(res[c]);
            }
         }
         if (app.appPath.length){
            var grpid=app.appPath.shift();
            call(function(){
               load_appl_scenario(grpid,function(){
                  if (app.appPath.length){
                     var applid=app.appPath.shift();
                     load_appldetail_scenario(applid,function(){
                        show_appldetail_scenario(applid);
                     });
                  }
                  else{
                     show_appl_scenario(grpid);
                  }
               });
            }); 
         }
         else{
            call(nextCall);
         }
         $.mobile.loading('hide');
       
      },{
        cistatusid:"4",
        name:"top*"
      }
   );

}

function show_mgmtitemgroup_scenario()
{
   var label="TopLists";
   $("#Elements-Container").html("");
   var ul=$('<ul id="listview" data-role="listview" '+
            'data-inset="true" style="height:100%"/>');
   ul.append("<li data-role='list-divider'>"+label+"</li>"); 
   //for (var name in target){
   for(c=0;c<app.mgmtitemgroup.rec.length;c++){
      var rec=app.mgmtitemgroup.rec[c];
      var li=$('<li />').attr({
         id:rec.id,
         name:rec.name
      });
      li.html("<a class='list-href' rel='external' "+
              "id='"+rec.id+"' href='#"+rec.id+"'>"+
              rec.name+
              "</a>");
      ul.append(li);
   }
   $("#Elements-Container").append(ul);
   $('#home').trigger("create");
   
   $(".list-href").click(function(){
      $.mobile.loading('show');
       var grpid=$(this).attr("id");
       app.orgPath=[grpid];
       load_appl_scenario(grpid,function(){
          show_appl_scenario(grpid);
       });
   });
}
//  Application List Scenario
function load_appl_scenario(grpid,nextCall)
{
   var groupname=app.mgmtitemgroup.id[String(grpid)].name;
   loadList('itil::appl','name,id',function(res){
      app.appl={rec:[],id:{}};
      for(c=0;c<res.length;c++){
         app.appl.id[String(res[c].id)]=res[c];
         app.appl.rec.push(res[c]);
      }
      nextCall();
   },{
      cistatusid:"4",
      mgmtitemgroup:groupname
   });
}

function show_appl_scenario()
{
   var label="ApplList";
   $("#Elements-Container").html("");
   var ul=$('<ul id="listview" data-role="listview" '+
            'data-inset="true" style="height:100%"/>');
   ul.append("<li data-role='list-divider'>"+label+"</li>"); 
   for(c=0;c<app.appl.rec.length;c++){
      var rec=app.appl.rec[c];
      var li=$('<li />').attr({
         id:rec.id,
         name:rec.name
      });
      li.html("<a class='list-href' rel='external' id='"+rec.id+"' href='#"+
              app.orgPath.join("-")+"-"+rec.id+"'>"+rec.name+"</a>");
      ul.append(li);
   }
   $("#Elements-Container").append(ul);
   $('#home').trigger("create");
   
   $(".list-href").click(function(){
      $.mobile.loading('show');
       var applid=$(this).attr("id");
       app.orgPath=[app.mgmtitemgroup.id,applid];
       load_appldetail_scenario(applid,function(){
          show_appldetail_scenario(applid);
       });
   });
   $.mobile.loading('hide');
}

function load_appldetailstat_scenario(nextCall)
{
   $.mobile.loading('show');
   $("#Elements-Container").append(
      "<h2 align=\"center\">RiManOS: Statistik</h2>"
   );
   $("#Elements-Container").append(
      "<div id='stat'>building stats ...</div>"
   );
   loadList('AL_TCom::appl','name,itemsummary,description,id',function(res){
      app.appldetail=res[0];
      nextCall();
   },{
      id:app.appldetail.id
   });
}

function show_appldetailstat_scenario(applid)
{
   $("#stat").html("done!");

   //data generation for dataquality
   var isum=app.appldetail.itemsummary.xmlroot;
   var dataquality={
      ok:0,
      fail:0,
      total:0
   };
   for(c=0;c<isum.dataquality.record.length;c++){
      dataquality.total+=1;
      if (isum.dataquality.record[c].dataissuestate=="OK"){
         dataquality.ok++;
      }
      else{
         dataquality.fail++;
      }
   }
   var dataquality_data=[
      {
         label:"DataIssue OK",
         data:dataquality.ok,
         color:"green"
      },
      {
         label:"DataIssue fail",
         data:dataquality.fail,
         color:"red"
      }
   ];

   //visualisation
   $("#stat").html("<div id='dataquality' style='border-style:solid;border-color:gray;padding:5px;width:240px;height:100px' />");
   var placeholder=$("#dataquality");
   $.plot(placeholder,dataquality_data,{
      series:{
         pie:{
            radius:0.8,
            show:true
         }
      }
   });

   $.mobile.loading('hide');
}


//  ApplicationDetail List Scenario
function load_appldetail_scenario(applid,nextCall)
{
   loadList('itil::appl','name,description,id',function(res){
      app.appldetail=res[0];
      nextCall();
   },{
      id:applid
   });
}



function show_appldetail_scenario(applid)
{
   var label="ApplList";
   var description=app.appldetail.description;

   description=description.replace(/\n/g,"<br>");


  

   $("#Elements-Container").html("");
   $("#Elements-Container").append("<h1>"+app.appldetail.name+"</h1>");
   $("#Elements-Container").append("<p id=\"desc\"></p>");
   $("#desc").html(description);

   call(function(){
       load_appldetailstat_scenario(show_appldetailstat_scenario);
   });
}


// Application Main
function runApp(){
   
   var target = document.location.hash.replace(/^#/,'');
   var appPath=target.split("-");
   app.orgPath=$.grep(appPath,function(a){return(a!="");});
   app.appPath=$.grep(appPath,function(a){return(a!="");});
   // appPath contains the current Hash

   $.mobile.loading('show');
   load_mgmtitemgroup_scenario(function(){
      show_mgmtitemgroup_scenario();
   });
}


$(document).ready(function (){
   call(runApp);
   $('#back-btn').click(function(){
      $.mobile.loading('show');
      app.appPath=[];
      call(function(){
         load_mgmtitemgroup_scenario(function(){
            show_mgmtitemgroup_scenario();
         });
      });
   });
});



function loadList(dataobj,view,nextCall,filter)
{
   var o=getModuleObject(W5Base,dataobj);
   o.SetFilter(filter);  
   o.findRecord(view,function(res){
      return(nextCall(res));
   });
}









function loadElements(dataobj,filter,view,label,recCallback,clickCallback)
{
   $.mobile.loading('show');
   var o=getModuleObject(W5Base,dataobj);
   o.SetFilter(filter);  
   o.findRecord(view,function(res){
      $("#Elements-Container").html("");
      var ul=$('<ul id="listview" data-role="listview" '+
               'data-inset="true" style="height:100%"/>');
      ul.append("<li data-role='list-divider'>"+label+"</li>"); 
      for(c=0;c<res.length;c++){
         var li=$('<li />').attr({
            id:res[c].id,
            name:res[c].name
         });
         li.html(recCallback(res[c]));
         ul.append(li);
      }
      $("#Elements-Container").append(ul);
      $('#home').trigger("create");
      
      $(".list-href").click(clickCallback);
      $.mobile.loading('hide');
   });
}


