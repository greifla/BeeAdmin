import net.w5base.mod.AL_TCom.workflow.businesreq.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator; 
import org.apache.log4j.Logger; 
import java.util.*;
import java.text.*;


public class businessreq {
  public static void main(String [] args) throws Exception {
    PropertyConfigurator.configure("log4j.properties"); 
    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.businesreq.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.businesreq.Port          W5Port;
    net.w5base.mod.AL_TCom.workflow.businesreq.WfRec         WfRec;
    net.w5base.mod.AL_TCom.workflow.businesreq.Record        CurRec;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp   Inp;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecOut   Res;
    net.w5base.mod.AL_TCom.workflow.businesreq.Filter        Flt;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp FInput;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service=
      new net.w5base.mod.AL_TCom.workflow.businesreq.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowBusinesreq();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    //
    // create a new workflow
    //
    WfRec=new net.w5base.mod.AL_TCom.workflow.businesreq.WfRec();
    Inp=new net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp();
    WfRec.setName("This is a test AL_TCom Business Request");
    WfRec.setDetaildescription("This is the description of my request\n"+
                               "This description can have more than one line");
    WfRec.setAffectedapplication("W5Base/Darwin");

    Inp.setData(WfRec);

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println("BUG="+Res.getLastmsg()[0]);
       System.exit(1);
    }
    System.out.println("new WorkflowID="+Res.getIdentifiedBy());
 
    //
    // find an existing workflow
    //
    FInput=new net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp();
    Flt=new net.w5base.mod.AL_TCom.workflow.businesreq.Filter();
    Flt.setId(Res.getIdentifiedBy());
    FInput.setFilter(Flt);
    FInput.setView("posibleactions,detaildescription,mdate,name,stateid");

    // do the Query
    Result=W5Port.findRecord(FInput);

    // show the Result
    CurRec=null;
    for (net.w5base.mod.AL_TCom.workflow.businesreq.Record rec: 
         Result.getRecords()){
       CurRec=rec;
    }
    //
    //  work arround with CurRec
    //

    if (CurRec!=null){
       System.out.println(CurRec.getName()+" = "+CurRec.getStateid());
       SimpleDateFormat df = new SimpleDateFormat( "dd.MM.yyyy HH:mm:ss" );
       System.out.println("mdate = "+df.format(CurRec.getMdate().getTime()));
       System.out.println("posible actions= "+
                    itguru.join(CurRec.getPosibleactions(),", "));
      
       if (itguru.exitsIn(CurRec.getPosibleactions(),"wfbreak")){
          System.out.printf("break is OK at now\n");
       }
       else{
          System.out.printf("break is NOT OK at now\n");
       }
    }

  }
}
