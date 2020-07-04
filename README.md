# freebsd_triage_and_qa
Some scripts to help with triage and qa of ports PRs

Requires *bash*

Just do:

```
./triage.sh <PR number>
```

And the script will:

 * Check the PR entry in Bugzilla for common mistakes or things to improve.
 * Download the port and check if it exists
 * Apply patches if any
 * Run some linters to see the global state of the port
