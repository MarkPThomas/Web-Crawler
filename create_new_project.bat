SET project=A_NEW_PROJECT

xcopy "%cd%\skeleton\*.*" "%cd%\%project%\" /s/h/e/k/f/c

cd %project%

rename NAME.gemspec %project%.gemspec

rename tests\test_NAME.rb test_%project%.rb
rename lib\NAME.rb %project%.rb

rename bin\NAME %project%
rename lib\NAME %project%

@echo ===========================================================
@echo The following files need to be renamed to the project name:
dir/s/b *NAME*