  # Process the ping times from the passed-in file, and summarize the results
  # grep to keep lines that have "time=", then sed to isolate the time stamps, and sort them
  # Use awk to build an array of those values, and print first & last (which are min, max) 
  # and compute average.
  # If the number of samples is >= 10, also compute median, and 10th and 90th percentile readings

  # Display the values as:
  #   Latency: (in msec, 11 pings, 8.33% packet loss)
  #    Min: 16.556
  #  10pct: 16.561
  # Median: 22.370
  #    Avg: 21.203
  #  90pct: 23.202
  #    Max: 23.394

summarize_pings() {     
  
grep "time" < "$1" | cat | \
sed 's/^.*time=\([^ ]*\) ms/\1/'| \
  # tee >&2 | \
  sort -n | \
  awk 'BEGIN {numdrops=0; numrows=0} \
    { \
      # print ; \
      if ( $0 ~ /timeout/ ) { \
          numdrops += 1; \
      } else { \
        numrows += 1; \
        arr[numrows]=$1; sum+=$1; \
      } \
    } \
    END { \
      pc10="-"; pc90="-"; med="-"; \
      if (numrows == 0) {numrows=1} \
      if (numrows>=10) \
      { # get the 10th pctile - never the first one
        ix=int(numrows/10); if (ix=1) {ix+=1}; pc10=arr[ix]; \
        # get the 90th pctile
        ix=int(numrows*9/10);pc90=arr[ix]; \
        # get the median
        if (numrows%2==1) med=arr[(numrows+1)/2]; else med=(arr[numrows/2]); \
      }; \
      pktloss = numdrops/(numdrops+numrows) * 100; \
      printf("\n  Latency: (in msec, %d pings, %4.2f%% packet loss)\n      Min: %4.3f \n    10pct: %4.3f \n   Median: %4.3f \n      Avg: %4.3f \n    90pct: %4.3f \n      Max: %4.3f\n", numrows, pktloss, arr[1], pc10, med, sum/numrows, pc90, arr[numrows] )\
     }'
}
