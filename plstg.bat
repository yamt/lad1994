@echo off
if not exist %1lstg.s1 goto not_find
if exist __tmp__.tmp goto tmp_err
if exist lstg.dat ren lstg.dat __tmp__.tmp
ren %1lstg.s1 lstg.dat
lad
ren lstg.dat %1lstg.s1
if exist __tmp__.tmp ren __tmp__.tmp lstg.dat
goto end

:tmp_err
echo �u__tmp__.tmp�v���Ă̂��L��ƍ���܂��`
goto end

:not_find
echo �u%1lstg.s1�v�Ȃ�Č�����Ȃ���ł���...

:end
