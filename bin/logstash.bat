@echo off

SETLOCAL

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..") do set LS_HOME=%%~dpfI

if "%USE_RUBY%" == "1" (
goto setup_ruby
) else (
goto setup_jruby
)

:setup_ruby
set RUBYCMD=ruby
set VENDORED_JRUBY=
goto EXEC

:setup_jruby
REM setup_java()
if not defined JAVA_HOME goto missing_java_home
REM ***** JAVA options *****

if "%LS_MIN_MEM%" == "" (
set LS_MIN_MEM=256m
)

if "%LS_MAX_MEM%" == "" (
set LS_MAX_MEM=1g
)

set JAVA_OPTS=%JAVA_OPTS% -Xms%LS_MIN_MEM% -Xmx%LS_MAX_MEM%

REM Enable aggressive optimizations in the JVM
REM    - Disabled by default as it might cause the JVM to crash
REM set JAVA_OPTS=%JAVA_OPTS% -XX:+AggressiveOpts

set JAVA_OPTS=%JAVA_OPTS% -XX:+UseParNewGC
set JAVA_OPTS=%JAVA_OPTS% -XX:+UseConcMarkSweepGC
set JAVA_OPTS=%JAVA_OPTS% -XX:+CMSParallelRemarkEnabled
set JAVA_OPTS=%JAVA_OPTS% -XX:SurvivorRatio=8
set JAVA_OPTS=%JAVA_OPTS% -XX:MaxTenuringThreshold=1
set JAVA_OPTS=%JAVA_OPTS% -XX:CMSInitiatingOccupancyFraction=75
set JAVA_OPTS=%JAVA_OPTS% -XX:+UseCMSInitiatingOccupancyOnly

REM GC logging options -- uncomment to enable
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCDetails
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCTimeStamps
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintClassHistogram
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintTenuringDistribution
REM JAVA_OPTS=%JAVA_OPTS% -XX:+PrintGCApplicationStoppedTime
REM JAVA_OPTS=%JAVA_OPTS% -Xloggc:/var/log/logstash/gc.log

REM Causes the JVM to dump its heap on OutOfMemory.
set JAVA_OPTS=%JAVA_OPTS% -XX:+HeapDumpOnOutOfMemoryError
REM The path to the heap dump location, note directory must exists and have enough
REM space for a full heap dump.
REM JAVA_OPTS=%JAVA_OPTS% -XX:HeapDumpPath=$LS_HOME/logs/heapdump.hprof

REM setup_vendored_jruby()
set JRUBY_BIN="%LS_HOME%\vendor\jruby\bin\jruby"
if exist "%JRUBY_BIN%" (
set VENDORED_JRUBY=1
goto EXEC
) else (
goto missing_jruby
)

:EXEC
REM run logstash
set RUBYLIB=%LS_HOME%\lib
REM is the first argument a flag? If so, assume 'agent'
set first_arg=%1
setlocal EnableDelayedExpansion
if "!first_arg:~0,1!" equ "-" (
  if "%VENDORED_JRUBY%" == "" (
    %RUBYCMD% "%LS_HOME%\lib\logstash\runner.rb" agent %*
  ) else (
    %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\logstash\runner.rb" agent %*
  )
) else (
  if "%VENDORED_JRUBY%" == "" (
    %RUBYCMD% "%LS_HOME%\lib\logstash\runner.rb" %*
  ) else (
    %JRUBY_BIN% %jruby_opts% "%LS_HOME%\lib\logstash\runner.rb" %*
  )
)
goto finally

:missing_java_home
echo JAVA_HOME environment variable must be set!
pause
goto finally

:missing_jruby
echo Unable to find JRuby.
echo If you are a user, this is a bug.
echo If you are a developer, please run 'rake bootstrap'. Running 'rake' requires the 'ruby' program be available.
goto finally

:finally

ENDLOCAL
