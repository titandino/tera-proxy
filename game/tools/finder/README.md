Finder
======
This tool helps find IDs for known message structures. This works in two parts.

Calibration
-----------
Based on known messages, we can:
* save values for fields that can only have certain values
* verify that the known messages pass all heuristic checks

Because of this, it's important to feed lots of log data even if you're not looking
for any particular messages.

Guessing
--------
This is where the heuristics mainly come into play. With a bit of guesswork, the
tool will try to figure out which messages map to which structure. For more complex
messages, it is likely to find matches with 100% certainty. Others will either need
manual inspection or another pass when more message IDs have been assigned.

Usage
=====
First, you'll need to install dependencies. Simply run `npm install` while in this
directory to take care of that in one fell swoop.

Next, run the tool with a log file as the only argument:
`coffee index.coffee <filename>`

The output will be written to a timestamped file in the `data` directory. That's it!
