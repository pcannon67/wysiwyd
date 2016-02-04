/*
* Copyright (C) 2014 WYSIWYD Consortium, European Commission FP7 Project ICT-612139
* Authors: Gregoire Pointeau, Maxime Petit
* email:   gregoire.pointeau@inserm.fr, m.petit@imperial.ac.uk
* website: http://wysiwyd.upf.edu/
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

#ifndef __EFAA_SUBSYSTEM_LRH_H__
#define __EFAA_SUBSYSTEM_RLH_H__

#define SUBSYSTEM_LRH        "lrh"

#include "wrdac/subsystems/subSystem.h"
#include "wrdac/subsystems/subSystem_ABM.h"

#include <iostream>

namespace wysiwyd{
    namespace wrdac{

        /**
        * \ingroup wrdac_clients
        *
        * Abstract subSystem for speech recognizer
        */
        class SubSystem_LRH : public SubSystem
        {
        protected:
            virtual bool connect() {
                // paste master name of 
                return yarp::os::Network::connect(portRPC.getName(), "/lrh/rpc");
            }
            SubSystem_ABM* SubABM;
            bool ABMconnected() {
                bool b = SubABM->Connect() && bForwardABM;
                yInfo() << (b ? "LRH connected to ABM" : "LRH not connected to ABM");
                return b;
            }

        public:
            bool bForwardABM;
            std::string interlocutor;
            std::string narrator;

            yarp::os::Port portRPC;

            SubSystem_LRH(const std::string &masterName) : SubSystem(masterName){
                portRPC.open(("/" + m_masterName + "/lrh:o").c_str());
                interlocutor = "partner";
                narrator = "iCub";
                m_type = SUBSYSTEM_LRH;
                bForwardABM = true;
                SubABM = new SubSystem_ABM(m_masterName + "/lrh");
            }


            virtual void Close() {
                portRPC.interrupt();
                portRPC.close();
                SubABM->Close();
            }


            std::string meaningToSentence(std::string sInput)
            {
                yarp::os::Bottle bMessenger,
                    bReturn;
                bMessenger.addString("production");
                bMessenger.addString(sInput);

                if (connect()){
                    portRPC.write(bMessenger, bReturn);
                    if (bReturn.size() == 2){
                        if (ABMconnected()){
                            std::list<std::pair<std::string, std::string> > lArgument;
                            lArgument.push_back(std::pair<std::string, std::string>(sInput, "meaning"));
                            lArgument.push_back(std::pair<std::string, std::string>(bReturn.get(1).toString(), "sentence"));
                            lArgument.push_back(std::pair<std::string, std::string>(m_masterName, "provider"));
                            lArgument.push_back(std::pair<std::string, std::string>(narrator, "speaker"));
                            lArgument.push_back(std::pair<std::string, std::string>(interlocutor, "addressee"));
                            SubABM->sendActivity("action", "production", "lrh", lArgument, true);
                        }
                        return bReturn.get(1).asString();
                    }
                    else{
                        yInfo() << "in subsystem lrh, error in meaningToSentence.";
                        return "none";
                    }
                }
                else {
                    yInfo() << "in subsystem lrh, LRH not connected: bypassing.";
                    return "none";
                }
            }

            std::string SentenceToMeaning(std::string sInput)
            {
                yarp::os::Bottle bMessenger,
                    bReturn;
                bMessenger.addString("meaning");
                bMessenger.addString(sInput);

                if (connect()){
                    portRPC.write(bMessenger, bReturn);
                    if (bReturn.size() == 2){
                        if (ABMconnected()){
                            std::list<std::pair<std::string, std::string> > lArgument;
                            lArgument.push_back(std::pair<std::string, std::string>(sInput, "sentence"));
                            lArgument.push_back(std::pair<std::string, std::string>(bReturn.get(1).toString(), "meaning"));
                            lArgument.push_back(std::pair<std::string, std::string>(m_masterName, "provider"));
                            lArgument.push_back(std::pair<std::string, std::string>("iCub", "addressee"));
                            lArgument.push_back(std::pair<std::string, std::string>(interlocutor, "speaker"));
                            SubABM->sendActivity("action", "comprehension", "lrh", lArgument, true);
                        }
                        return bReturn.get(1).asString();
                    }
                    else{
                        yInfo() << "in subsystem lrh, error in sentenceToMeaning.";
                        return "none";
                    }
                }
                else {
                    yInfo() << "in subsystem lrh, LRH not connected: bypassing.";
                    return "none";
                }
            }

        };
    }
}
//Namespace
#endif

