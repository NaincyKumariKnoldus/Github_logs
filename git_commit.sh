#!/bin/bash

getCommitResponse=$(
   curl -s \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://github.com/NaincyKumariKnoldus/Github_logs/commits?sha=$GITHUB_REF_NAME&per_page=100
)

# get commit SHA
commitSHA=$(echo "$getCommitResponse" |
   jq '.[].sha' |
   tr -d '"')
# echo "commitSHA= $commitSHA"

loopCount=$(echo "$commitSHA" |
   wc -w)
echo "loopcount= $loopCount"

rm -rf sha_es.txt
# get data from ES
getEsCommitSHA=$(curl -H "Content-Type: application/json" -X GET "$ES_URL/github/_search?pretty" -d '{
                  "size": 10000,                                                                  
                  "query": {
                     "wildcard": {
                           "commit_sha": {
                              "value": "*"
                           }}}}' |
                  jq '.hits.hits[]._source.commit_sha' |
                  tr -d '"')

echo $getEsCommitSHA | tr " " "\n" > sha_es.txt
rm -rf match.txt
rm -rf unmatch.txt

for ((count = 0; count < $loopCount; count++)); do
   # get commitSHA
   commitSHA=$(echo "$getCommitResponse" |
      jq --argjson count "$count" '.[$count].sha' |
      tr -d '"')

   matchRes=$(grep -o $commitSHA sha_es.txt)
   echo $matchRes | tr " " "\n" >> match.txt
   echo $matchRes
   # echo $matchRes | wc -c
   if [ -z $matchRes ]; then
      echo "Unmatched SHA: $commitSHA"
      echo $commitSHA | tr " " "\n" >> unmatch.txt
      # get author name
      authorName=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.author.name' |
         tr -d '"')

      # get commit message
      commitMessage=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.message' |
         tr -d '"')

      # get commit html url
      commitHtmlUrl=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].html_url' |
         tr -d '"')

      # get commit time
      commitTime=$(echo "$getCommitResponse" |
         jq --argjson count "$count" '.[$count].commit.author.date' |
         tr -d '"')

      # send data to es
      curl -X POST "$ES_URL/github_commit/commit" \
         -H "Content-Type: application/json" \
         -d "{ \"commit_sha\" : \"$commitSHA\",
            \"branch_name\" : \"$GITHUB_REF_NAME\",
            \"author_name\" : \"$authorName\",
            \"commit_message\" : \"$commitMessage\",
            \"commit_html_url\" : \"$commitHtmlUrl\",
            \"commit_time\" : \"$commitTime\" }"
   else
      echo non-empty_skip
   fi
done
# remove temporary file
echo "Data From ES"
echo "ES_Data_count:"
cat sha_es.txt | wc -l
cat sha_es.txt
echo
echo "-------------------------------------------"
echo "Match data from ES"
echo "Match data count:"
cat match.txt | wc -l
cat match.txt
echo
echo "-------------------------------------------"
echo "UnMatch data from ES"
echo "UnMatch data count:"
cat unmatch.txt | wc -l
cat unmatch.txt
