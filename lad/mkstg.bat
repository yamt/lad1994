@echo off
if exist _tmp_.tmp goto tmp_err
if exist %1lstg.s1 ren %1lstg.s1 _tmp_.tmp
mkladstg
if exist _tmp_.tmp ren _tmp_.tmp %1lstg.s1
goto end

:tmp_err
echo 「_tmp_.tmp」ってのが有ると困るんですが...

:end
