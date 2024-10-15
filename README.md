This project is a powershell based program that will create a replica of a source folder into another (<source-folder-name>-replica by default)
It accepts for example `./folder-sync.ps1 ./test` and creates a folder named `test-replica` in the same
directory with all the files inside `./test`.
it also accepts the flag `-i` so the script runs in the background.
