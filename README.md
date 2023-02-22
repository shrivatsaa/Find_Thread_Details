# Find_Thread_Details
Script to provide overview of thread stack with user and request details.It is very useful especially in scenarios where we need to find what cycles a thread went through or what activity it is currently involved in. 
So here is an attempt at bridging the disconnect and optical difficulty  while looking at thread dumps in traditional thread dump analyzers 

There are two prerequisites for gathering such an overview of thread:
Add a thread identifier %I to the access log valve in server.xml
Have the access log and the thread dumps in the same folder for analysis.

Have a thread identifier %I added to the access log valve in server.xml in a format such as below. currently the script looks for the thread identifier to be the second column in the below pattern.
But it can be modified as explained in one of the comment section in the script.

pattern="%a %I %{jira.request.id}r %{jira.request.username}r %t &quot;%m %U%q %H&quot; %s %b %D &quot;%{Referer}i&quot; &quot;%{User-Agent}i&quot; &quot;%{jira.request.assession.id}r&quot;"

Then the entry in the access log would look something similar to the below entry

142.136.96.252 http-nio-8080-exec-39 1162x35050x7 User6852 [10/Feb/2023:19:22:32 -0500] "GET /rest/api/2/issue/10000/subtask/move?_=1676074886672 HTTP/1.1" 200 14 210 "http://localhost:8080/browse/SCRUM-67754" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" "2ox7nu" 

The script can be run as follows

./GiveMeThreadDetails.sh <folder containing tdumps and accesslog> <Date in DD-MON-YYYY>
Example : ./GiveMeThreadDetails.sh Threads 10-Feb-2023
