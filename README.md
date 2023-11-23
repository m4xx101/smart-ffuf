# Smart-ffuf

## Overview

smart-ffuf.sh is a shell script that enhances the functionality of the ffuf fuzzing tool. It automates fuzzing across multiple targets and intelligently moves to the next target if similar responses are detected consecutively.

## Features

Automates ffuf runs on multiple targets.
Tracks the line count in responses.
Moves to the next target if the same line count is detected in 15 consecutive responses.

## Usage

```sh
./smart-ffuf.sh -i <input domain or file> -w <wordlist> [-a <additional ffuf args>] [-r <rate>]
```

- -i: Domain or file with list of domains/IPs.
- -w: Wordlist file for ffuf.
- -a: (Optional) Additional arguments for ffuf.
- -r: (Optional) Rate limit for ffuf requests (default: 10).
