/*
* Copyright (C) 2014 WYSIWYD Consortium, European Commission FP7 Project ICT-612139
* Authors: St�phane Lall�e
* email:   stephane.lallee@gmail.com
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

#ifndef __CVZ_CVZSTACK_H__
#define __CVZ_CVZSTACK_H__
#include "yarp/os/ResourceFinder.h"
#include "ICvz.h"
#include "CvzBuilder.h"
#include <list>
#include <map>

namespace cvz {
	namespace core {

		/**
		* CvzStack
		* A simple helper class that allows to create a graph of CVZ from code
		* and to manage the connections between those.
		*/
		class CvzStack: public yarp::os::RFModule
		{
			std::list< ThreadedCvz* > nodes;
			std::map<std::string, IModality* > nodesIO;
			std::map< IModality*, std::map<IModality*, bool > > connections;
			
			/**
			* Update.
			*/
			bool updateModule()
			{
				return true;
			}

			/**
			* Complete the connection matrix by setting to false the connections that do not exist.
			*/
			void fillConnectionMatrix()
			{
				//1. complete the matrix
				for (std::map<std::string, IModality* >::iterator it = nodesIO.begin(); it != nodesIO.end(); it++)
				{
					if (connections.find(it->second) == connections.end())
					{
						connections[it->second][it->second] = false;
					}
				}

				//2. fill the gaps
				for (std::map<std::string, IModality* >::iterator it = nodesIO.begin(); it != nodesIO.end(); it++)
				{
					for (std::map<std::string, IModality* >::iterator it2 = nodesIO.begin(); it2 != nodesIO.end(); it2++)
					{
						if (connections[it->second].find(it2->second) == connections[it->second].end())
						{
							connections[it->second][it2->second] = false;
						}
					}
				}
			}

		public:

			bool respond(const yarp::os::Bottle &command, yarp::os::Bottle &reply)
			{
				if (command.get(0).asString() == "addCvz")
				{
					reply.addInt( addCvz(command.get(1).asString().c_str(), command.get(2).asString().c_str()) );
				}
				else
				{
					reply.addInt(0);
				}
				return true;
			}
			/**
			* Setup.
			*/
			bool configure(yarp::os::ResourceFinder &rf)
			{
				return true;
			}

			/**
			* Stop every convergence zone running and then close the model.
			*/
			bool close()
			{
				for (std::list<ThreadedCvz*>::iterator it = nodes.begin(); it != nodes.end(); it++)
				{
					(*it)->stop();
					delete (*it);
				}
				return true;
			}

			/**
			* Add a new CVZ from a config file. The CVZ is instantiated and added to the graph.
			* @param configFile Name of the config file containing the information about the cvz.
			* @return true/false on success/failure.
			*/
			bool addCvz(std::string configFile, std::string overrideName="")
			{

				yarp::os::ResourceFinder rf;
				rf.setVerbose(true);
				rf.setDefaultContext("cvz");
				rf.setDefaultConfigFile(configFile.c_str());
				rf.configure(NULL, NULL);			

				yarp::os::Property prop; prop.fromConfigFile(rf.findFile("from"));

				if (prop.check("name") && overrideName != "")
				{
					prop.unput("name");
					prop.put("name", overrideName);
				}

				ThreadedCvz* newCvz = new ThreadedCvz(prop, 100);
				if(newCvz->start())
					nodes.push_back(newCvz);
				else return false;

				//Expand the connection list and the connection matrix
				for (std::map<std::string, IModality* >::iterator it = newCvz->cvz->modalitiesBottomUp.begin(); it != newCvz->cvz->modalitiesBottomUp.end(); it++)
					nodesIO[it->second->GetFullName()] = it->second;
				for (std::map<std::string, IModality* >::iterator it = newCvz->cvz->modalitiesTopDown.begin(); it != newCvz->cvz->modalitiesTopDown.end(); it++)
					nodesIO[it->second->GetFullName()] = it->second;

				fillConnectionMatrix();
				return true;
			}
			

			/**
			* Connect two modalities given their names (i.e: /cvzName/modalityName ).
			* Also establish the yarp connection between them.
			* @param from Source modality name.
			* @param to Target modality name.
			* @param tryConnectYarp Do you want to establish the yarp connection now (true) or just add it to the graph?
			* @return True/False in case of success/failure.
			*/
			bool connectModalities(std::string from, std::string to, bool tryConnectYarp=true)
			{
				connections[nodesIO[from]][nodesIO[to]] = true;
				bool result = true;
				if (tryConnectYarp)
				{
					result &= yarp::os::Network::connect(nodesIO[from]->GetFullNamePrediction(), nodesIO[to]->GetFullNameReal());
					result &= yarp::os::Network::connect(nodesIO[to]->GetFullNamePrediction(), nodesIO[from]->GetFullNameReal());
				}
				return result;
			}

			/**
			* Connect all modalities following the graph connection matrix.
			* Also establish the yarp connection between them.
			* @param from Source modality name.
			* @param to Target modality name.
			* @return True/False in case of success/failure.
			*/
			void connectModalities()
			{
				for (std::map<std::string, IModality* >::iterator it = nodesIO.begin(); it != nodesIO.end(); it++)
				{
					for (std::map<std::string, IModality* >::iterator it2 = nodesIO.begin(); it2 != nodesIO.end(); it2++)
					{
						if (connections[it->second][it2->second])
						{
							connectModalities(it->first, it2->first);
						}
					}
				}
			}
		};
	}
}
#endif