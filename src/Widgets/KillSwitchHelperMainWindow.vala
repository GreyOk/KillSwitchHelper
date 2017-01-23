/* The MIT License
*
* Copyright (c) 2017 은성
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

using Gtk;
using Gdk;
using Pango;

/**
 * Class containing the generation of the main window its widgets and all the logic of the signals.
 */
 public class KillSwitchHelperMainWindow : Gtk.Application {

   // Variable containing the grid that contains the routes
   private Grid routesGrid = null;

   private int routesGridX = 0;
   private int routesGridY = 0;

   // Variable containing the grid that contains the history
   private Grid deletedRoutesGrid = null;
   private int deletedRoutesGridY = 0;

   // Variable containing all the switches
   Switch[] allRouteSwitches = {};

   // Polkit action variable
   private string actionID = "killswitchhelper.execute.iproute";

   // Variable containing the history
   string[] deletedHistoryArray = {};

   // Variable containing the clear history button
   Button clearHistoryButton = null;

   // Variable containing the refresh Button
   Button routesRefreshButton = null;

   // Variable containing the quit menu item
   Gtk.MenuItem killSwitchHelperQuitMenuItem = null;

   // Variable containing the how to use menu item
   Gtk.MenuItem howToUseMenuItem = null;
   // Variable containing the how to use dialog
   Dialog howToUseDialog = null;

   // Variable containing the about menu item
   Gtk.MenuItem killSwitchHelperAboutMenuItem = null;

   // The about dialog
   AboutDialog killSwitchHelperAboutDialog = null;

   // Constructor
   public KillSwitchHelperMainWindow () {
     Object (application_id: "killSwitchHelper.app",
     flags: ApplicationFlags.FLAGS_NONE);
   }

   protected override void activate () {
     try {
        // Create the builder
        var builder = new Builder ();

        // Check if the glade file exists in the same directory
        bool fileInExecutableDirectory = FileUtils.test ("KillSwitchHelper.glade", FileTest.EXISTS);
        // Get the home directory
        // string homeDirectory = Environment.get_home_dir ();

        // Check if the glade file exists in the application data specific directory
        bool fileInApplicationDataSpecificDirectory = FileUtils.test ("/usr/share/KillSwitchHelper/KillSwitchHelper.glade", FileTest.EXISTS);

        if (fileInExecutableDirectory) {
                // Glade file is in the same executable path, load it with our builder
                builder.add_from_file ("KillSwitchHelper.glade");
        }
        else if (fileInApplicationDataSpecificDirectory) {
                // Load the glade file with our builder from the application data directory
                builder.add_from_file("/usr/share/KillSwitchHelper/KillSwitchHelper.glade");
        }
        else{
                // We couldn't load the glade file
                stderr.printf (_("Could not find KillSwitchHelper.glade file in the executable directory, nor in the application data specific directory.\nThe program should have come with a file named 'KillSwitchHelper.glade' in the same directory it was delivered and if CMake was run, it should have created the file as: ") + "/usr/share/KillSwitchHelper/KillSwitchHelper.glade" + "\n");
                this.quit ();
        }

        builder.connect_signals (this);

        // Create a new instance of this Gtk Application
        var killSwitchMainWindow = new Gtk.ApplicationWindow (this);

        killSwitchMainWindow = builder.get_object ("killSwitchHelperMainWindow") as ApplicationWindow;
        // Set the initial position of the window
        killSwitchMainWindow.set_position (Gtk.WindowPosition.CENTER);
        // Connect the destroy signal to quit the application
        killSwitchMainWindow.destroy.connect (this.quit);
        //Set the css of the MainWindow
        CssProvider provider = new CssProvider ();
        Gdk.Display display = Gdk.Display.get_default ();
        Gdk.Screen screen = display.get_default_screen ();

        Gtk.StyleContext.add_provider_for_screen (screen, provider, 600);

        string cssData = "GtkApplicationWindow {\n
            background: white;\n}\n
          GtkStackSwitcher {\n
            background: white;\n}\n
          GtkStack {\n
            background-color: white;\n}\n
          .tooltip {\n
            background-color:rgba(0, 0, 0, 0.6);\n
            }\n
            GtkDialog {\n
              background-color: white;\n}\n
            .tooltip {\n
              background-color:rgba(0, 0, 0, 0.6);\n
              }";
        provider.load_from_data (cssData);

        // Load the grid containing the routes
        routesGrid = builder.get_object ("routesGrid") as Grid;
        if (routesGrid == null) debug ("\nCould not get the grid.\n");

        // Load the grid containing the history
        deletedRoutesGrid = builder.get_object ("deletedRoutesGrid") as Grid;

        // Load the clear history button
        this.clearHistoryButton = builder.get_object ("clearConfigurationButton") as Button;

        // Load the refresh button
        this.routesRefreshButton = builder.get_object ("routesRefreshButton") as Button;

        // Load the quit menu item
        this.killSwitchHelperQuitMenuItem = builder.get_object ("killSwitchHelperQuitMenuItem") as Gtk.MenuItem;

        // Load the how to use menu item
        this.howToUseMenuItem = builder.get_object ("howToUseMenuItem") as Gtk.MenuItem;
        // Load the how to use dialog
        this.howToUseDialog = builder.get_object ("howToUseDialog") as Dialog;
        this.howToUseDialog.set_destroy_with_parent (true);
	      //this.howToUseDialog.set_modal (true);

        // Load the about menu item
        this.killSwitchHelperAboutMenuItem = builder.get_object ("killSwitchHelperAboutMenuItem") as Gtk.MenuItem;

        // Load the About dialog
        this.killSwitchHelperAboutDialog = builder.get_object ("killSwitchHelperAboutDialog") as AboutDialog;
        this.killSwitchHelperAboutDialog.set_destroy_with_parent (true);
	      this.killSwitchHelperAboutDialog.set_modal (true);
        this.killSwitchHelperAboutDialog.logo_icon_name = "killswitchhelper";

        //Connect all signals
        connect_signals();

        // Show the main window
        killSwitchMainWindow.show ();

        // Check if there is any deleted history and read it
        readDeletedHistory ();

        //Populate the routing table
        populateRoutingTable ();

      }
      catch(GLib.Error e){
              stderr.printf ("Error + %s", e.message);
      }
    }

   // Get the routing table and populate it
   public void populateRoutingTable () {
     // The setting for the first query of the routes
     string[] iproute2Arguments = {"ip", "route", "show"};
     // The setting for the second query of the routes
     string[] iproute2Arguments2 = {"ip", "route", "show", "table", "local"};

     // The settings for all iproute2 queries and commands
  	 string[] processEnvironment = Environ.get ();
  	 string iproute2_stdout;
  	 string iproute2_stderr;
  	 int iproute2_status;

     try {
       // Get the main route table
       Process.spawn_sync ("/",
               iproute2Arguments,
               processEnvironment,
               SpawnFlags.SEARCH_PATH,
               null,
               out iproute2_stdout,
               out iproute2_stderr,
               out iproute2_status);

        // Output: For debugging uncomment the following line. Then execute the program with G_MESSAGES_DEBUG=all to show debug messages
		    //debug ("%s", iproute2_stdout);

        // Get all the output lines
        string[] outputLines = iproute2_stdout.split ("\n");
        //debug ("\n%s", outputLines[0]);

        // Get the local route table
        Process.spawn_sync ("/",
                iproute2Arguments2,
                processEnvironment,
                SpawnFlags.SEARCH_PATH,
                null,
                out iproute2_stdout,
                out iproute2_stderr,
                out iproute2_status);

        // Get all the output lines for local routes
        //string[] localRoutesOutputLines = iproute2_stdout.split ("\n");
        //debug ("\n%s", localRoutesOutputLines[0]);

        // Regex to fix double spaces
        Regex spacesExpression = /\s\s+/;

        // Loop through all the main routes
        for(var i = 0; i < outputLines.length - 1; i++) {
          // Replace double spaces with spaces
          string lineToSplit = spacesExpression.replace (outputLines[i], outputLines[i].length, 0, " ");
          // Split the line using spaces
          string[] strippedLine = lineToSplit.split (" ");
          // Lets create the user interface
          Box newBox = new Box (Orientation.VERTICAL, 6);
          newBox.baseline_position  = BaselinePosition.CENTER;
          newBox.homogeneous = true;
          newBox.margin = 6;

          Label label1 = new Label (_("Name/IP: "));
          Label label2 = new Label (_("Gateway: "));
          Label label3 = new Label (_("Device/Interface: "));
          Label label4 = new Label (_("Protocol: "));
          Label label5 = new Label (_("Scope: "));
          Label label6 = new Label (_("Source: "));

          if (!lineToSplit.contains ("scope")) {
            label1.set_label (_("Name/IP: ") + strippedLine[0]);
            if (strippedLine[1].contains ("via")) label2.set_label (_("Gateway: ") + strippedLine[2]);
            if (strippedLine[3].contains ("dev")) label3.set_label (_("Device/Interface: ") + strippedLine[4]);
            if (strippedLine[5].contains ("proto")) label4.set_label (_("Protocol: ") + strippedLine[6]);
            label5.set_label (_("Scope: N/A"));
            label6.set_label (_("Source: N/A"));
          }
          else if (lineToSplit.contains ("scope")) {
            label1.label = _("Name/IP: ") + strippedLine[0];
            label2.set_label (_("Gateway: "));
            if (strippedLine[1].contains ("dev")) label3.label = _("Device/Interface: ") + strippedLine[2];
            if (strippedLine[3].contains ("proto")) label4.label = _("Protocol: ") + strippedLine[4];
            if (strippedLine[5].contains ("scope")) label5.label = _("Scope: ") + strippedLine[6];
            if (strippedLine[7].contains ("src")) label6.label = _("Source: ") + strippedLine[8];
          }

          Gtk.Switch newRouteSwitch = new Gtk.Switch ();
          newRouteSwitch.active = true;
          newRouteSwitch.halign = Align.END;
          newRouteSwitch.valign = Align.START;
          lineToSplit = customTrim (lineToSplit);
          newRouteSwitch.set_data ("command", lineToSplit);
          newRouteSwitch.set_data ("splittedCommand", strippedLine);
          newRouteSwitch.set_data ("active", true);
          newRouteSwitch.set_data ("activatedByUndo", false);
          newRouteSwitch.notify["active"].connect (() => {
            // Get the location of the ip program
            string[] ipLocation_args = {"which", "ip"};
            string[] ipLocation_env = Environ.get ();
            string ipLocation_stdout;
            string ipLocation_stderr;
            int ipLocation_status;
            string ipLocation = "";
            try {
              Process.spawn_sync ("/",
                        ipLocation_args,
                        ipLocation_env,
                        SpawnFlags.SEARCH_PATH,
                        null,
                        out ipLocation_stdout,
                        out ipLocation_stderr,
                        out ipLocation_status);
              ipLocation = ipLocation_stdout;
              // Tell the user if the program could not be found
              if (ipLocation_stdout == "" || ipLocation_status != 0) {
                Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR, Gtk.ButtonsType.OK,
                "The program 'ip' could not be found in the system PATH. This application makes use of it and it will not work without it.\n
                You can install it by running the following command in a terminal: 'sudo apt-get install iproute2' or
                by looking for it in a package manager by the name 'iproute2'.");
                failMessage.response.connect ((response_id) => {
                  switch (response_id) {
                    case Gtk.ResponseType.OK:
                      break;
                  }
                  failMessage.destroy();
                });
                failMessage.show ();
              }
            } catch (SpawnError e) {
              Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "There was an error trying to get the location of the ip program.");
              failMessage.response.connect ((response_id) => {
                switch (response_id) {
                  case Gtk.ResponseType.OK:
                    break;
                }
                failMessage.destroy();
              });
              failMessage.show ();
              stdout.printf ("Process spawn error: %s\n", e.message);
            }
      			if (newRouteSwitch.active) {
              // Check if this was not triggered by a not authorized result or a dismiss result
              bool isActive = newRouteSwitch.get_data ("active");
              bool activatedByUndo = newRouteSwitch.get_data ("activatedByUndo");
              if (!isActive && !activatedByUndo) {
                string command = newRouteSwitch.get_data("command");
                try {
                      // We are authorized. Let's prepare the helper program to execute the command to add a route
                      string finalCommand = "sudo ip route add " + command;
                      string[] spawn_args = {"pkexec", "killswitchhelperhelper", actionID, finalCommand, command};
                  		string[] spawn_env = Environ.get ();
                  		string killswitchhelperhelper_stdout;
                  		string killswitchhelperhelper_stderr;
                  		int killswitchhelperhelper_status;

                  		Process.spawn_sync ("/",
                  							spawn_args,
                  							spawn_env,
                  							SpawnFlags.SEARCH_PATH,
                  							null,
                  							out killswitchhelperhelper_stdout,
                  							out killswitchhelperhelper_stderr,
                  							out killswitchhelperhelper_status);
                      if (killswitchhelperhelper_stdout.contains ("File exists")) {
                        // Show a message saying that the route exists
                        Gtk.MessageDialog routeExists = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK, "The route already exists. Nothing was done.");
                        routeExists.response.connect ((response_id) => {
                     			switch (response_id) {
                     				case Gtk.ResponseType.OK:
                     					break;
                     			}
                     			routeExists.destroy();
                     		});
                        routeExists.show ();
                      } else {
                        if (!killswitchhelperhelper_stdout.contains ("Route modify success.")) {
                          // We were not authorized, return the switch to active state
                          newRouteSwitch.set_active (false);
                          newRouteSwitch.replace_data<bool, bool> ("activatedByUndo", activatedByUndo, false, null);
                          Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Adding route failed. Either the authentication failed because it was dismissed, the given credentials were wrong, or the program 'ip' could not be found in the system path. It can also mean that a route with a prefix must be added before adding the route you intend to add.");
                          failMessage.response.connect ((response_id) => {
                       			switch (response_id) {
                       				case Gtk.ResponseType.OK:
                       					break;
                       			}
                       			failMessage.destroy();
                       		});
                          failMessage.show ();
                        }
                        else {
                          newRouteSwitch.replace_data<bool,bool> ("active", isActive, true, null);
                          newRouteSwitch.replace_data<bool, bool> ("activatedByUndo", activatedByUndo, false, null);
                          Gtk.MessageDialog successMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "The route has been successfully added.");
                          successMessage.response.connect ((response_id) => {
                       			switch (response_id) {
                       				case Gtk.ResponseType.OK:
                       					break;
                       			}
                       			successMessage.destroy();
                       		});
                          successMessage.show ();
                        }
                      }
                  } catch (SpawnError e) {
                    Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "There was an error launching the helper to add the route. Most probably, the installation of the executable for the helper failed. Please uninstall and then reinstall the whole program.");
                    failMessage.response.connect ((response_id) => {
                 			switch (response_id) {
                 				case Gtk.ResponseType.OK:
                 					break;
                 			}
                 			failMessage.destroy();
                 		});
                    failMessage.show ();
                    stdout.printf ("Process spawn error: %s\n", e.message);
                  }
              }
      			} else {
                bool isActive = newRouteSwitch.get_data ("active");
                bool activatedByUndo = newRouteSwitch.get_data ("activatedByUndo");
                // Check if this was not triggered by a not authorized result or a dismiss result
                if (isActive && !activatedByUndo) {
                  // Delete the route
                  string command = newRouteSwitch.get_data("command");

                  try {
                        // We are authorized. Let's prepare the helper program to execute the command to delete a route
                        string finalCommand = "sudo ip route del " + command;
                        string[] spawn_args = {"pkexec", "killswitchhelperhelper", actionID, finalCommand, command};
                    		string[] spawn_env = Environ.get ();
                    		string killswitchhelperhelper_stdout;
                    		string killswitchhelperhelper_stderr;
                    		int killswitchhelperhelper_status;

                    		Process.spawn_sync ("/",
                    							spawn_args,
                    							spawn_env,
                    							SpawnFlags.SEARCH_PATH,
                    							null,
                    							out killswitchhelperhelper_stdout,
                    							out killswitchhelperhelper_stderr,
                    							out killswitchhelperhelper_status);
                                  stdout.printf ("%s\n", killswitchhelperhelper_stdout);
                                  stdout.printf ("%s\n", killswitchhelperhelper_stderr);
                                  stdout.printf ("%d\n", killswitchhelperhelper_status);

                        if (!killswitchhelperhelper_stdout.contains ("Route modify success.")) {
                          // We were not authorized, return the switch to active state
                          newRouteSwitch.active = true;
                          newRouteSwitch.replace_data<bool, bool> ("activatedByUndo", activatedByUndo, false, null);
                          Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Deleting route failed. Either the authentication failed because it was dismissed, the given credentials were wrong, or the program 'ip' could not be found in the system path.");
                          failMessage.response.connect ((response_id) => {
                       			switch (response_id) {
                       				case Gtk.ResponseType.OK:
                       					break;
                       			}
                       			failMessage.destroy();
                       		});
                          failMessage.show ();
                        } else {
                          newRouteSwitch.replace_data<bool, bool> ("active", isActive, false, null);
                          newRouteSwitch.replace_data<bool, bool> ("activatedByUndo", activatedByUndo, false, null);
                          writeDeleteHistory (command);
                          createUndoHistory (command);
                          Gtk.MessageDialog successMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "The route has been successfully removed.");
                          successMessage.response.connect ((response_id) => {
                       			switch (response_id) {
                       				case Gtk.ResponseType.OK:
                       					break;
                       			}
                       			successMessage.destroy();
                       		});
                          successMessage.show ();
                        }
                    } catch (SpawnError e) {
                      Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "There was an error launching the helper to add the route. Most probably, the installation of the executable for the helper failed. Please uninstall and then reinstall the whole program.");
                      failMessage.response.connect ((response_id) => {
                   			switch (response_id) {
                   				case Gtk.ResponseType.OK:
                   					break;
                   			}
                   			failMessage.destroy();
                   		});
                      failMessage.show ();
                      stdout.printf ("Process spawn error: %s\n", e.message);
                    }
                }
      			}
            bool activatedByUndo = newRouteSwitch.get_data ("activatedByUndo");
            newRouteSwitch.replace_data<bool, bool> ("activatedByUndo", activatedByUndo, false, null);
      		});
          newRouteSwitch.show_all ();
          allRouteSwitches += newRouteSwitch;
          newBox.pack_start (newRouteSwitch, false, true, 0);
          newBox.pack_start (label1, false, true, 0);
          newBox.pack_start (label2, false, true, 0);
          newBox.pack_start (label3, false, true, 0);
          newBox.pack_start (label4, false, true, 0);
          newBox.pack_start (label5, false, true, 0);
          newBox.pack_start (label6, false, true, 0);

          Frame newFrame = new Frame ("");
          newFrame.add (newBox);

          // The counters for the grid accomodation
          if (this.routesGridX == 0) {
            this.routesGrid.attach (newFrame, routesGridX, routesGridY, 1, 1);
            this.routesGridX++;
          }
          else if (this.routesGridX == 1) {
            this.routesGridX++;
            this.routesGrid.attach (newFrame, routesGridX, routesGridY, 1, 1);
            this.routesGridX = 0;
            this.routesGridY++;
          }

          routesGrid.show_all ();

        }
     } catch (SpawnError e) {
       stdout.printf (_("Process spawn error: %s\n"), e.message);
     } catch (RegexError e) {
       stdout.printf (_("Regular expression error: %s\n"), e.message);
     }
   }

   private void writeDeleteHistory (string command) {
          // The file with the history
          var deletedRoutesHistory = File.new_for_path (Environment.get_home_dir () + "/.config/KillSwitchHelper/deletedRoutesHistory.txt");
          // The data directory
          var dataDirectory = File.new_for_path (Environment.get_home_dir () + "/.config/KillSwitchHelper");
          try {
            // Create the data directory if it does not exis
            if (!dataDirectory.query_exists ()) dataDirectory.make_directory ();

            // Check if file already exists
            if (deletedRoutesHistory.query_exists ()) {
              MainLoop loop = new MainLoop ();
              // Let's write to the end of it
              deletedRoutesHistory.open_readwrite_async.begin (Priority.DEFAULT, null, (obj, res) => {
                            		try {
                            			FileIOStream iostream = deletedRoutesHistory.open_readwrite_async.end (res);
                            			iostream.seek (0, SeekType.END);

                            			OutputStream ostream = iostream.output_stream;
                            			DataOutputStream dostream = new DataOutputStream (ostream);
                            			dostream.put_string (command + "\n");
                            		} catch (Error e) {
                            			stdout.printf (_("Error: %s\n"), e.message);
                            		}
                            		loop.quit ();
                            	});

                            	loop.run ();
            } else {
              // Create the file
              // Create a new file with this name
              deletedRoutesHistory.create (FileCreateFlags.PRIVATE);

              MainLoop loop = new MainLoop ();
              // Let's write to the end of it
              deletedRoutesHistory.open_readwrite_async.begin (Priority.DEFAULT, null, (obj, res) => {
                            		try {
                            			FileIOStream iostream = deletedRoutesHistory.open_readwrite_async.end (res);
                            			iostream.seek (0, SeekType.END);

                            			OutputStream ostream = iostream.output_stream;
                            			DataOutputStream dostream = new DataOutputStream (ostream);
                            			dostream.put_string (command + "\n");
                                  stdout.printf ("%s\n", command);
                            		} catch (Error e) {
                            			stdout.printf (_("Error: %s\n"), e.message);
                            		}
                            		loop.quit ();
                            	});

                            	loop.run ();
            }
          } catch (Error e) {
            stdout.printf ("Error: %s\n", e.message);
          }
    }

    private void readDeletedHistory () {
           // The file with the history
           var deletedRoutesHistory = File.new_for_path (Environment.get_home_dir () + "/.config/KillSwitchHelper/deletedRoutesHistory.txt");
           try {
               // Check if file already exists
               if (deletedRoutesHistory.query_exists ()) {
                 var dis = new DataInputStream (deletedRoutesHistory.read ());
                  string line;
                  // Read lines until end of file (null) is reached
                  while ((line = dis.read_line (null)) != null) {
                      createUndoHistory (line);
                  }
               }
           } catch (Error e) {
             stdout.printf (_("Error: %s\n"), e.message);
           }
     }

     private void createUndoHistory (string command) {
       stdout.printf ("%s\n", command);
       stdout.printf ("%s\n", deletedHistoryArray[0]);
       // Create the deleted routes history user interface
       Box newBox = new Box (Orientation.VERTICAL, 6);
       newBox.baseline_position  = BaselinePosition.CENTER;
       newBox.homogeneous = true;
       newBox.margin = 6;
       Label label1 = new Label ("Route: " + command);
       label1.set_line_wrap (true);
       Button undoButton = new Button.from_icon_name ("edit-undo", IconSize.BUTTON);
       undoButton.set_data("command", command);
       undoButton.set_label (_("Undo"));
       undoButton.always_show_image = true;

       bool isInArray = false;
       // Set the array of history
       foreach (string s in deletedHistoryArray) {
         if (s.contains (command)) isInArray = true;
       }
       if (!isInArray) {
         deletedHistoryArray += command;
         // Set the button clicked signals
         undoButton.clicked.connect (() => {
               string assignedCommand = undoButton.get_data("command");
               try {
                     // We are authorized. Let's prepare the helper program to execute the command to add a route
                     string finalCommand = "sudo ip route add " + command;
                     string[] spawn_args = {"pkexec", "killswitchhelperhelper", actionID, finalCommand, command};
                     string[] spawn_env = Environ.get ();
                     string killswitchhelperhelper_stdout;
                     string killswitchhelperhelper_stderr;
                     int killswitchhelperhelper_status;

                     Process.spawn_sync ("/",
                               spawn_args,
                               spawn_env,
                               SpawnFlags.SEARCH_PATH,
                               null,
                               out killswitchhelperhelper_stdout,
                               out killswitchhelperhelper_stderr,
                               out killswitchhelperhelper_status);
                     if (killswitchhelperhelper_stdout.contains ("File exists")) {
                       // Show a message saying that the route exists
                       Gtk.MessageDialog routeExists = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK, "The route already exists. Nothing was done.");
                       routeExists.response.connect ((response_id) => {
                    			switch (response_id) {
                    				case Gtk.ResponseType.OK:
                    					break;
                    			}
                    			routeExists.destroy();
                    		});
                       routeExists.show ();
                     } else {
                       if (!killswitchhelperhelper_stdout.contains ("Route modify success.")) {
                         // We were not authorized, notify the user that nothing happened
                         Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Adding route failed. Either the authentication failed because it was dismissed, the given credentials were wrong, or the program 'ip' could not be found in the system path. It can also mean that a route with a prefix must be added before adding the route you intend to add.");
                         failMessage.response.connect ((response_id) => {
                      			switch (response_id) {
                      				case Gtk.ResponseType.OK:
                      					break;
                      			}
                      			failMessage.destroy();
                      		});
                         failMessage.show ();
                       }
                       else {
                         // We were authorized and route was added, tell the user
                         Gtk.MessageDialog successMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "The route has been successfully added.");
                         successMessage.response.connect ((response_id) => {
                      			switch (response_id) {
                      				case Gtk.ResponseType.OK:
                      					break;
                      			}
                      			successMessage.destroy();
                            for (int i = 0; i < allRouteSwitches.length; i++) {
                              string switchData = allRouteSwitches[i].get_data("command");
                              bool isActive = allRouteSwitches[i].get_data("active");
                              if (switchData.contains(assignedCommand)) {
                                allRouteSwitches[i].set_data ("activatedByUndo", true);
                                allRouteSwitches[i].replace_data<bool, bool> ("active", isActive, true, null);
                                allRouteSwitches[i].set_active (true);
                              }
                            }
                            // Delete all the routes from the user interface only
                            List<weak Widget> listOfChildren = this.routesGrid.get_children ();
                            foreach (Gtk.Widget element in listOfChildren) {
                              this.routesGrid.remove (element);
                              element.destroy ();
                            }
                            // Reset the routes grid variables
                            this.routesGridX = 0;
                            this.routesGridY = 0;
                            // Re-populate the routes
                            populateRoutingTable ();
                      		});
                         successMessage.show ();
                       }
                     }
                 } catch (SpawnError e) {
                   Gtk.MessageDialog failMessage = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "There was an error launching the helper to add the route. Most probably, the installation of the executable for the helper failed. Please uninstall and then reinstall the whole program.");
                   failMessage.response.connect ((response_id) => {
                			switch (response_id) {
                				case Gtk.ResponseType.OK:
                					break;
                			}
                			failMessage.destroy();
                		});
                   failMessage.show ();
                   stdout.printf (_("Process spawn error: %s\n"), e.message);
                 }
         });

         newBox.pack_start (label1, false, false, 0);
         newBox.pack_start (undoButton, false, false, 0);
         Frame newFrame = new Frame ("");
         newFrame.add (newBox);

         this.deletedRoutesGrid.attach (newFrame, 0, deletedRoutesGridY, 1, 1);
         deletedRoutesGridY++;
         deletedRoutesGrid.show_all ();
       }
     }

     // Function for the clear button clicked signal
     void clearButtonCallback () {
       // Display a message asking the user whether to really delete the history
       Gtk.MessageDialog reallyDeleteMessageDialog = new Gtk.MessageDialog (this.get_active_window (), Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.YES_NO, "Do you really want to delete the history of removed routes? If they don't get re-added to the routing table, they won't be recoverable through this application.");
       reallyDeleteMessageDialog.response.connect ((response_id) => {
          switch (response_id) {
            case Gtk.ResponseType.YES:
              List<weak Widget> listOfChildren = this.deletedRoutesGrid.get_children ();
              foreach (Gtk.Widget element in listOfChildren) {
                this.deletedRoutesGrid.remove (element);
                element.destroy ();
              }
              // Remove the file with the history
              try {
                var historyFile = File.new_for_path (Environment.get_home_dir () + "/.config/KillSwitchHelper/deletedRoutesHistory.txt");
                if (historyFile.query_exists ()) {
                    historyFile.delete ();
                    deletedHistoryArray = {};
                }
              } catch (Error e) {
                stdout.printf (_("Error: %s\n"), e.message);
              }
              break;
          }
          reallyDeleteMessageDialog.destroy();
        });
       reallyDeleteMessageDialog.show ();
     }

     public void refreshButtonCallback () {
       // Delete all the routes from the user interface only
       List<weak Widget> listOfChildren = this.routesGrid.get_children ();
       foreach (Gtk.Widget element in listOfChildren) {
         this.routesGrid.remove (element);
         element.destroy ();
       }
       // Reset the routes grid variables
       this.routesGridX = 0;
       this.routesGridY = 0;
       // Re-populate the routes
       populateRoutingTable ();
     }

     // Quit menu item activated callback
     public void quitMenuItemCallback () {
       // Quit the application
       this.quit ();
     }

     // Help menu item activated callback
     public void helpMenuItemCallback () {
       // Show the About dialog
       this.killSwitchHelperAboutDialog.show ();
       this.killSwitchHelperAboutDialog.response.connect ((response_id) => {
      		if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
      			this.killSwitchHelperAboutDialog.hide_on_delete ();
      		}
      	});
     }

     // The How to use menu item activated callback
     public void howToUseMenuItemCallback () {
       (this.howToUseDialog as Gtk.Window).show_all ();
       this.howToUseDialog.response.connect ((response_id) => {
      		if (response_id == 1 || response_id == Gtk.ResponseType.DELETE_EVENT) {
      			this.howToUseDialog.hide_on_delete ();
      		}
      	});
     }

     public void connect_signals () {
       // Connect the clear history button
       this.clearHistoryButton.clicked.connect (clearButtonCallback);
       // Connect the refresh button clicked signal
       this.routesRefreshButton.clicked.connect (refreshButtonCallback);
       // Connect the quit button
       this.killSwitchHelperQuitMenuItem.activate.connect (quitMenuItemCallback);
       // Connect the how to use menu button
       this.howToUseMenuItem.activate.connect (howToUseMenuItemCallback);
       // Connect the help menu item activate signal
       this.killSwitchHelperAboutMenuItem.activate.connect (helpMenuItemCallback);
     }

     //Function to trim leading and trailing spaces
     private string customTrim(string theString){
             string newString = null;
             try {
                     //Regex to trim trailing spaces
                     Regex regex = new Regex ("\\s+$");
                     //Regex to trim leading spaces
                     Regex regex2 = new Regex ("^\\s+");
                     newString = regex.replace (theString, theString.length, 0, "");
                     newString = regex2.replace (newString, newString.length, 0, "");
             } catch (RegexError e) {
                     stdout.printf ("Error: %s\n", e.message);
             }
             return newString;
     }
 }
