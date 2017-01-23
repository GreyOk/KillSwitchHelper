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

using Polkit;
public static int main (string[] args) {

  // Polkit and command variables
  Subject? subject = null;
  string actionID;
  string finalCommand;
  string command;
  Authority? authority = null;
  GLib.Cancellable? cancellable = null;
  AuthorizationResult? authorizationResult = null;
  Details? details = null;
  stdout.printf ("Number of arguments: %d\n", args.length);
  // Check that the arguments match exactly 4
  if (args.length == 4) {
    actionID = args[1];
    finalCommand = args[2];
    command = args[3];
    // Get the process ID and user ID to be used for Polkit
    int pid = Posix.getpid ();
    int uid = (int) Posix.getuid ();
    try {
      // Get the polkit authority
      authority = Polkit.Authority.get_sync (cancellable);

      // Make sure we are not a zombie process
      if (pid == 1) {
        stdout.printf ("Parent process was reaped by init(1). We are a zombie process. Proceeding to quit.\n");
        // Quit if we are a zombie process
        return -1;
      }

      // Get the Polkit subject to be used to check for authentication
      subject = Polkit.UnixProcess.new_for_owner (pid, 0, uid);
      // Prepare the polkit authentication message variable
      details = new Details ();
      if (finalCommand.contains ("del")) details.insert ("polkit.message", "Authentication is required to DELETE route '" +  command + "' using 'ip route'");
      else if (finalCommand.contains ("add")) details.insert ("polkit.message", "Authentication is required to ADD route '" +  command + "' using 'ip route'");

      // Check for authorization. If the operating system has an authentication agent with GUI, this will open it and ask the user to
      // authenticate if the process AND the user is not already authorized. If the process AND user is already authorized to perform the action
      // it will not open any kind of window to authenticate the user and will automatically return the authorization data
      authorizationResult = authority.check_authorization_sync (subject, actionID, details, Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION, cancellable);

      // Check if the authorizationResult is not null
      if (authorizationResult != null) {
        // Check if the we are authorized to perform the actionID
        if (authorizationResult.get_is_authorized ()) {
          string[] spawn_args = {};
          // Commands that represent a danger to the operating system if executed
          string[] commandsThatShouldNotExist = {"rm ", "cat ", ">", "<", "mkfs", "wget ", "dd ", "python ", ":(){:|:&};:", "unzip ", "mv ", "\\xeb\\"};
          // Trim the command to be executed
          command = customTrim (command);
          // Check if there are dangerous commands mixed
          foreach (string dangerousCommand in commandsThatShouldNotExist) {
            if (command.contains (dangerousCommand)) {
              // A dangerous command was injected. Return.
              stderr.printf ("Dangerous command. Aborting.");
              return -1;
            }
          }
          // Set the spawn process arguments
          if (finalCommand.contains ("del")) spawn_args = {"sudo", "ip", "route", "del"};
          else spawn_args = {"sudo", "ip", "route", "add"};
          string[] splittedCommand = command.split (" ");
          for (int i = 0; i < splittedCommand.length; i++) spawn_args += splittedCommand[i];

          string command_stdout;
          string command_stderr;
          int command_status;
          try {
            // Inherit the parent working directory and parent environment set by pkexec.
            Process.spawn_sync (null,
                      spawn_args,
                      null,
                      SpawnFlags.SEARCH_PATH,
                      null,
                      out command_stdout,
                      out command_stderr,
                      out command_status);
            stdout.printf ("%s\n", command_stderr);
            stdout.printf ("%s\n", command_stdout);
            stdout.printf ("%d", command_status);
            if (command_status == 0) {
              stdout.printf ("Route modify success.");
            } else {
              stderr.printf ("%s", command_stderr);
            }
          } catch (SpawnError e) {
            stdout.printf ("Process spawn error: %s\n", e.message);
          }
        }
        else {
          if (authorizationResult.get_dismissed()) stderr.printf ("Dismissed by user.");
          return -1;
        }
      }
    } catch (Polkit.Error e) {
      stderr.printf ("Polkit error: %s\n", e.message);
    } catch (GLib.Error e) {
      stderr.printf ("\nGLib error: %s\n", e.message);
    }
  } else {
    return -1;
  }
  return 0;
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
