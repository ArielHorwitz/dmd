#! /bin/bash

command="$@"
files="rg --files --hidden"
echo "Files initially tracked:"
echo `$files`

while true; do
  `echo $files` | entr -dcps "$command ; date ; echo Press control+z to exit. ;"
done

