# Test scaffolding for the summarize_pings() subroutine.
# Take a known set of ping readings (in ./pingsamples.txt), strip out bogus stuff, 
# then pass the first N lines (passed in as an argument) to the summarize_pings() function
# 

# include the summarize_pings() function from the library
. "../lib/summarize_pings.sh"

PINGFILE=$(mktemp /tmp/measurepings.XXXXXX) || exit 1

# pre-format the pingsamples for ease of counting...
# strip out any line that doesn't contain "time" (e.g., not time= or timeout)
# Only send the specified number of lines into $PINGFILE
cat < pingsamples.txt | \
grep time | \
head -n "$1" > "$PINGFILE" 
echo "=== PINGFILE ==="
cat "$PINGFILE"
echo "========"
summarize_pings "$PINGFILE"
rm "$PINGFILE"


