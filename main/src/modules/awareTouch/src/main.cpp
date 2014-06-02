// -*- mode:C++; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

/*
 * Copyright (C) 2014 WYSIWYD Consortium, European Commission FP7 Project ICT-612139
 * Authors: Hector Barron-Gonzalez (ported by Mathew Evans and Uriel Martinez)
 * email:   mat.evans@sheffield.ac.uk (but email Ugo Pattacini Ugo.Pattacini@iit.it after July 2014)
 * Permission is granted to copy, distribute, and/or modify this program
 * under the terms of the GNU General Public License, version 2 or any
 * later version published by the Free Software Foundation.
 *
 * A copy of the license can be found at
 * wysiwyd/license/gpl.txt
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details
*/


/*
 *
 * 
 * @ingroup efaa_modules
 * \defgroup awareTouch 
 *  
 *
 *
 * Recover information from Skin when iCub is externally touched, storing information into the OPC about position
 * and type of touching. The dependencies are OPC and skinManager. The gestures to be recognized must be added to the 
 * list "gestureTypes", in the config file.
 *
 * 
 * \section lib_sec Libraries
 *
 * YARP
 * ICUB
 *
 * \section parameters_sec Parameters
 * 
 * <b>Command-line Parameters</b> 
 * 
 * The following key-value pairs can be specified as command-line parameters by prefixing \c -- to the key 
 * (e.g. \c --from file.ini. The value part can be changed to suit your needs; the default values are shown below. 
 *
 * - \c from \c config.ini \n 
 *   specifies the configuration file
 *
 * - \c name \c awareTouch \n   
 *   specifies the name of the module (used to form the stem of module port names)  

 * - \c skinManagerPort \c /skinManager/skin_events:o \n    
 *   specifies the skinManager port  name
 *
 * - \c opcName \c OPC \n    
 *   specifies the opc database name
 *
 *
 * \section portsa_sec Ports Accessed
 * 
 * /OPC/rpc \n 
 * /skinManager/skin_events:o \n 
 *                      
 * \section portsc_sec Ports Created
 *
 * /awareTouch/skin_contacts:i \n 
 *
 * /awareTouch/events:o \n
 *
 * \section in_files_sec Input Data Files
 *
 * Gesture files (e.g. "poked.txt", "caressed.txt", etc)
 *
 * \section out_data_sec Output Data Files
 *
 * Tactile gestures file "Touching.txt"
 *
 * \section conf_file_sec Configuration Files
 *
 * \c config.ini  in \c $EFAAT/app/awareTouch/conf \n
 * 
 * \section tested_os_sec Tested OS
 *
 * Linux
 *
 * \section example_sec Example Instantiation of the Module
 * 
 * <tt>awareTouch </tt>
 * <tt>awareTouch --name awareTouch --opcName OPCGeneral --skinManagerPort /skinManager/skin_events:o </tt>
 *
 * \author Hector Barron-Gonzalez
 * 
 *
 * 
 */



#include <yarp/os/all.h>
#include <yarp/os/Network.h>
#include <yarp/os/RFModule.h>
#include <yarp/sig/all.h>
#include <yarp/dev/Drivers.h>

#include <wrdac/clients/opcClient.h>

#include "touchEstimationThread.h"
//#include <efaa/helpers/helpers.h>
//#include <efaa/helpers/clients/opcClient.h>
#include <iomanip>
#include <iostream>

YARP_DECLARE_DEVICES(icubmod)
using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace wysiwyd::wrdac;

class AwareTouch: public yarp::os::RFModule
{
   Port eventsPort;
   double recordingPeriod;
   vector<string> gestureSet;
   TouchEstimationThread *estimationThread;
   double lastAutoSnapshotTime;

   OPCClient  * world;
   Agent * icub;  
   Object * touchLocation;


    void sendOPC(const string &, int &,const Vector&, double );
public:
    bool configure(yarp::os::ResourceFinder &rf);
    bool close();
    bool interruptModule();
    double getPeriod();
    bool updateModule();
        
};




bool AwareTouch::configure(ResourceFinder &rf)
{  
   // Defining module
   string moduleName  = rf.check("name", Value("awareTouch")).asString().c_str();            // Check name of the module
   setName(moduleName.c_str());                                                                 // Assign this name for ports
   cout<< "||  Starting config "<< moduleName <<endl;  
   printf("Naming the module \n");
   string robot=rf.check("robot",Value("icubSim")).asString().c_str();                    //type of robot   
   cout<< "||  Robot :"<< robot <<endl;         
    
   // port for skin data
   string rpcName="/" ;
   rpcName += getName ( rf.check("inPort",Value("/skin_contacts:i")).asString() );               //input port name
 
   // port for output events
   string eventsName="/" ;
   eventsName += getName ( rf.check("eventPort",Value("/events:o")).asString() );               //events port name
   cout<< "||  Opening port  :"<< eventsName <<endl;
   eventsPort.open(eventsName.c_str());

   string skinManagerName  = rf.check("skinManagerPort", Value("/skinManager/skin_events:o")).asString().c_str();            // Check name of the module
   string opcName = rf.check("opcName", Value("OPC")).asString().c_str();
 
   //Generating a copy of the world from OPC
   world = new OPCClient("OPCTouch");
   while(!world->connect(opcName)){
       cout<< "Trying to connect OPC Server"<<endl;
   } 
   cout<< "||  Connected OPC  :" <<endl;

   // Generating type of gestures 
   cout<< "||  Reading files of gesture types  ... :" <<endl;               
   Bottle * gestureTypes=rf.find("gestureTypes").asList();
   cout<< "||  Gesture types ("<< gestureTypes->size()<<") "<<endl;


   //Populating the world with gestures and subjects
   gestureSet.clear();

   string gestureStr; 
   for (int iGesture=0;iGesture<gestureTypes->size(); iGesture++)   { 
     gestureStr=(gestureTypes->get(iGesture).asString().c_str() );
     gestureSet.push_back(gestureStr);
     cout<<gestureStr<<endl;
     world->addAdjective(gestureStr);
   }

    world->addAgent("icub");
    touchLocation = world->addObject("touchLocation");
    touchLocation->m_present = false;
    world->commit(touchLocation);
    world->addAction("is");
    world->addAdjective("none");
   

   // holding time in OPC 
    recordingPeriod=rf.check("recordingPeriod",Value(3.0)).asDouble();                    //type of robot   
    cout  << "|| Recording Period is " << recordingPeriod << endl ; 

    string pathG(rf.getContextPath().c_str());


   cout<< "|| Creating Touch  Thread:" <<endl;
   estimationThread= new TouchEstimationThread(skinManagerName, rpcName, pathG,gestureSet, 50);
   cout<< "|| Starting Touch  :" <<endl;
   estimationThread->start();
   cout<< "|| Started Touch  :" <<endl;   
   return true;
}




bool AwareTouch::updateModule()
{  
    string partTouch;
    int typeTouch;
    Vector positionTouched;
    double sizeTouched;
    sizeTouched=0;
    positionTouched.clear();
    positionTouched.resize(3);
    positionTouched.zero();
    double currentTime = Time::now();
    double timeSinceLastShot = currentTime - lastAutoSnapshotTime;
    
    estimationThread->bodyPartTouched( partTouch, typeTouch, positionTouched, sizeTouched);  //        <----- Recover type and location of tactile gesture
    if (typeTouch>-1) {  // if there was, indeed,  touching
        if (timeSinceLastShot>=recordingPeriod) {           // Does not put anything in OPC until last gesture is forgotten
            sendOPC(partTouch, typeTouch, positionTouched, sizeTouched);
        }
    }
    return true;
}


double AwareTouch::getPeriod()
{
   return 0.2;

}


bool AwareTouch::interruptModule()
{
   world->interrupt();
   estimationThread->stop();
   return true;
}



bool AwareTouch::close()
{
   world->close();
   eventsPort.close();
   return true;
}


void AwareTouch::sendOPC(const string &partTouch, int &typeTouch, const Vector& posTouch, double sizeTouched)
{
   Vector dimensions;
   dimensions.clear();
   dimensions.push_back(0.05);
   dimensions.push_back(0.05);
   dimensions.push_back(0.05);
   
   cout<<"Touch Pos:"<<posTouch.toString().c_str()<<endl;
   (touchLocation ->m_ego_position) = posTouch;
   (touchLocation ->m_dimensions) = dimensions;
   touchLocation->m_present = true;
   world->commit(touchLocation);   // add position of touching
   world->addRelation(Relation("icub","is",gestureSet[typeTouch], "touchLocation"), recordingPeriod);  // add the relation with gesture

   Bottle outEvent;
   Bottle &what=outEvent.addList();
   what.addString(partTouch.c_str());
   what.addString(gestureSet[typeTouch].c_str());
   Bottle &where=outEvent.addList();
   where.read(const_cast<Vector&>(posTouch));
   eventsPort.write(outEvent);

   cout<<"icub is being "<< gestureSet[typeTouch]<<" at:"<< posTouch.toString().c_str() <<endl;
   lastAutoSnapshotTime = Time::now();  
}
    



/************************************************************************/
int main(int argc, char *argv[])
{
    ResourceFinder rf;
    rf.setDefaultContext("awareTouch/conf");
    rf.setDefaultConfigFile("config.ini");
    rf.configure("EFAA_ROOT",argc,argv);

    YARP_REGISTER_DEVICES(icubmod)

    Network yarp;
    if (!yarp.checkNetwork())
        return -1;

    AwareTouch module;
    return module.runModule(rf);
}
