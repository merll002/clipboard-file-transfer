> [!CAUTION]
> I am very new to bash scripting, and as a result this script will have tons of bugs, possibly even ones leading to data loss! I am not responsible for any damage caused by this script.

## Clipboard file transfer over terminal
This bash script provides a <ins>**proof of concept**</ins> method of transferring files and folders over terminals via the clipboard.
For example, to transfer files over to a locked down machine via ssh with no internet access.

### Showcase
#### Benchmarking speed
![bench](https://github.com/user-attachments/assets/0c983107-4e2f-4d25-88b0-77b07e861948)
> It started off slow due to network traffic

#### Getting optimal compression method
![gcm](https://github.com/user-attachments/assets/dfef3f9f-3642-4c4e-8c65-1bd8bfb23ce5)

#### Transferring folder
![transfer](https://github.com/user-attachments/assets/19ae186f-a282-4b26-938b-b8968bac2b61)

### How to run this script (if you dare)
Download the latest `transfer.bash` script from the repo, and run with `bash transfer.bash`
> [!NOTE]
> Use middleclick paste, not `Ctrl + Shift + V`
>
> If you are on X11, then set the clipboard copy command with `-c` e.g., `fish -c 'fish_clipboard_copy'` for universal compatibility.

### Usage:
```
Usage: transfer.bash [command] [-c <method>] [-t <compression>] [file]

Arguments:
  -t  select compression type, e.g., `-t gz`
  -c  set clipboard copy method. Default: `wl-copy -p`

Commands:
  get-compression-method, gcm  Determine the optimal compression method supported on the target system
  bench                        Start a transfer speed benchmark (cool)

Examples:
  transfer.bash get-compression-method
  transfer.bash -t gzip file.txt  Transfer file with the gzip compression method
```
#### PRs please!
Any PRs would be appreciated (this script could do with some improvements)

<sub>And learning is fun!</sub>
