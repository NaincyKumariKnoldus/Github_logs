#!/bin/bash

getCommitResponse=$(curl -s \
                    -H "Accept: application/vnd.github+json" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    https://api.github.com/repos/NaincyKumariKnoldus/Github_logs/commits?sha=$GITHUB_REF_NAME&per_page=100&page=1)

# echo $getCommitResponse


# get commit SHA
commitSHA=$(echo "$getCommitResponse" |
   jq '.[].sha' |
   tr -d '"')
echo "commitSHA= $commitSHA"

loopCount=$(echo "$commitSHA" |
   wc -w)

# get data from ES
getEsCommitSHA=$(curl -X \
   GET "$ES_URL/github/_search?q=commit_sha:*" |
   jq '.hits.hits[]._source.commit_sha' |
   tr -d '"')

echo $getEsCommitSHA>test.txt

for ((count = 0; count < $loopCount; count++)); do

   # get commitSHA
   commitSHA=$(echo "$getCommitResponse" |
      jq --argjson count "$count" '.[$count].sha' |
      tr -d '"')

   matchRes=$(grep -o $commitSHA test.txt)
   if [ ! -z $matchRes ]; then
      echo skip
   else
      echo $commitSHA
      # get commit branch
      # branchRespone=$(curl \
      #    -H "Accept: application/vnd.github+json" \
      #    -H "X-GitHub-Api-Version: 2022-11-28" \
      #    'https://api.github.com/repos/NaincyKumariKnoldus/Github_logs/ship-log-to-es/commits/$commitSHA/branches-where-head)

      # getCommitBranch=$(echo "$branchResponse" |
      #    jq '.[].name' |
      #    tr -d '"')

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
      curl -X POST "$ES_URL/github/commit" \
         -H "Content-Type: application/json" \
         -d "{ \"commit_sha\" : \"$commitSHA\",
            \"branch_name\" : \"$GITHUB_REF_NAME\",
            \"author_name\" : \"$authorName\",
            \"commit_message\" : \"$commitMessage\",
            \"commit_html_url\" : \"$commitHtmlUrl\",
            \"commit_time\" : \"$commitTime\" }"
   fi
   # get commit branch
   # branchRespone=$(curl \
   #    -H "Accept: application/vnd.github+json" \
   #    -H "X-GitHub-Api-Version: 2022-11-28" \
   #    https://api.github.com/repos/aamir7knoldus/ship-log-to-es/commits/$commitSHA/branches-where-head)

   # getCommitBranch=$(echo "$branchResponse" |
   #    jq '.[].name' |
   #    tr -d '"')

   # # get author name
   # authorName=$(echo "$getCommitResponse" |
   #    jq --argjson count "$count" '.[$count].commit.author.name' |
   #    tr -d '"')

   # # get commit message
   # commitMessage=$(echo "$getCommitResponse" |
   #    jq --argjson count "$count" '.[$count].commit.message' |
   #    tr -d '"')

   # # get commit html url
   # commitHtmlUrl=$(echo "$getCommitResponse" |
   #    jq --argjson count "$count" '.[$count].html_url' |
   #    tr -d '"')

   # # get commit time
   # commitTime=$(echo "$getCommitResponse" |
   #    jq --argjson count "$count" '.[$count].commit.author.date' |
   #    tr -d '"')

   # # send data to es
   # curl -X POST "http://localhost:9200/github/commit" \
   #    -H "Content-Type: application/json" \
   #    -d "{ \"commit_sha\" : \"$commitSHA\",
   #          \"branch\" : \"$getCommitBranch\",
   #          \"author_name\" : \"$authorName\",
   #          \"commit_message\" : \"$commitMessage\",
   #          \"commit_html_url\" : \"$commitHtmlUrl\",
   #          \"commit_time\" : \"$commitTime\" }"

done
rm -rf test.txt
