# Ideas

As they come to me, a high level note of ideas to look at improving in the near future.

- [ ] Create a promote/demote script that will allow promotion of skills/memories/etc. between global and project scope. With/without encryption; mechanism needs to work across projects so use a dot folder for the encryption/decryption mechanism, and make sure only the prod/non-wip content gets committed.
- [ ] Make our scripting globally relevant;
  - [ ] Add it to path/install it to path somewhere
  - [ ] Move the encryption key to a shared env somewhere (we can use 1password and 1p cli to store, update and grab it, with a locally cached, excluded copy).
    - [ ] We may need a marker to ensure when it changes, and I jump to another box; I don't accidentally re-encrypt with the old key; which would potentially destroy data.
- [ ] Make the encryption mechanism generic, and shove it in zshconfig (~/projects/personal/zsh-config, make the config generic and portable between OSX, Ubuntu, and Raspian/Debian distros, OSX and Ubuntu are priority, de based is fallback for obscure boxes I work on, not as important, but we shouldn't paint ourselves into a corner.).
  - Keep a copy in here that can be used if the path-bound version is not found, and add rules to sync them regularly if both repos are local. i.e. if someone else uses this repo I want them to be able to do so effectively, without needing my zshconfig as well.
- [ ] Create cheat sheets (zsh config has the mechanism in the cht function, it is not the same as cht.sh).
  - [ ] The skills/memories scripts
  - [ ] The encryption mechanism
  - [ ] The update mechanisms and project seeding/updating mechanism (i.e. project-init).
  - [ ] Scan to see if there's any other useful cheatsheets I could employ here.