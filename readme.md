> [!CAUTION]
> I am very new to bash scripting, as a result, this script will have tons of bugs, possibly even ones leading to data loss! I am not responsible for any damage caused by this script.

## Clipboard file transfer over terminal
This bash script provides a <ins>**proof of concept**</ins> method of transferring files and folders over terminals via the clipboard.
For example, to transfer files over to a locked down machine via ssh with no internet access.

### How to run this script (if you dare)
Download the latest `transfer.bash` script from the repo, and run with `bash transfer.bash`
> [!NOTE]
> Use middleclick paste, not `Ctrl + Shift + V`
>
> If you are on X11, then swap the clipboard copy commands in the script (`wl-copy`).

### Usage:
```
Usage: clipboard-file-transfer/transfer.bash [command] [args] [file]

Args:
  -t  select compression type, e.g., `-t gz`

Commands:
  get-compression-method, gcm  Determine the optimal compression method supported on the target system
  bench                        Start a transfer speed benchmark (cool)

Examples:
  clipboard-file-transfer/transfer.bash get-compression-method
  clipboard-file-transfer/transfer.bash -t gzip file.txt  Transfer file with the gzip compression method
```
#### PRs please!
Any PRs would be appreciated (this script could do with some improvements)

<sub>And learning is fun!</sub>