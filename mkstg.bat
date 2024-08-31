@echo off
if exist _tmp_.tmp goto tmp_err
if exist %1lstg.s1 ren %1lstg.s1 _tmp_.tmp
mkladstg
if exist _tmp_.tmp ren _tmp_.tmp %1lstg.s1
goto end

:tmp_err
echo u_tmp_.tmpv‚Á‚Ä‚Ì‚ª—L‚é‚Æ¢‚é‚ñ‚Å‚·‚ª...

:end
