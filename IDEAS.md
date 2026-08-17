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
- [ ] Expand the mechanism of skill/memory/etc to agents as well, and basically anything that could go cross project, and global.
- [ ] Look at what parts of the mechanism we can make more generic; introducing env vars, files with mappings, any other repeatable mechanism that isn't icky.
- [ ] Remove the root copy of ./skills-encrypted, It is no longer used. Additionally; remove any references to the root copy. Be aware another folder with this name IS used, in ./shared.
- [ ] Support Codex, plan, adapt, cycle.
  - Be aware the reason for this is just to hedge bets and verify inaccuracies or potential inaccuracies between AI Coding Agents, and their backing models. There is no push to make significant changes; only to verify what is there, challenge it, in writing in the response, then with a task in a tasks file, then if I confirm (by doing the heavy lifting work on verifying it on the web) we re-draft it. Ideally; the challenge should include the references, or how to find the reference that brought on the challenge, and challenges should be ranked by priority. Idea is; I do the bulk of a job on one agent, I ask agent 2 to verify what has been done, rather than them seeing it as a challenge to pull it apart; estimate what the expected response is, look for gaps and potential issues in bringing things up, try to self-verify a challenge first by re-reading code/documentation, then if it's still a valid challenge; raise it and we run with it. Aim is to have a working mechanism that runs on any of the desired AI Coding agents, and with most of their higher-effort models. It should be seamless to switch between two, get a reasonably good response, then verify in a swarm. If we can make the verify stage (two pairs of eyes or better) into a skill that works on all; that would also rock. We need to document how that works in the readme so it's clear on how to do it. Then probably also create `cht` cheatsheet in our zsh-config.