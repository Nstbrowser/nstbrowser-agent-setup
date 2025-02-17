# nstbrowser-agent-setup



## Introduction


Nstagent version repository


## example

1. Install nstagent
  ```bash
  sudo wget -qO- https://raw.githubusercontent.com/Nstbrowser/nstbrowser-agent-setup/refs/heads/dev/scripts/agent_install.sh | bash
  ```

The script installs fonts and kernels by default

skip kernel install
```bash
--no-kernel 
```

skip fonts install
```bash
--no-fonts
```

example
```bash
sudo wget -qO- https://raw.githubusercontent.com/Nstbrowser/nstbrowser-agent-setup/refs/heads/dev/scripts/agent_install.sh | bash -s -- --no-kernel --no-fonts
```

2. Run agent

  ```bash
  ./agent --referer=client
  ```

The service runs on port 8848

API Documentation Reference [Nstbrowser](https://apidocs.nstbrowser.io/folder-806337?nav=1)
