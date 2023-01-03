#!/bin/bash

getCommitResponse=$(curl -s \
                    -H "Accept: application/vnd.github+json" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    https://api.github.com/repos/NaincyKumariKnoldus/Github_logs/commits)

# echo $getCommitResponse


# get commit SHA
commitSHA=$(echo "$getCommitResponse" | \
            jq '.[].sha'| \
            tr -d '"')


loopCount=$(echo "$commitSHA" | \
            wc -w)

for (( count=0; count<$loopCount; count++))
do
   commitSHA=$(echo "$getCommitResponse" | \
            jq --argjson count "$count" '.[$count].sha'| \
            tr -d '"')
      # get author name
   authorName=$(echo "$getCommitResponse" | \
               jq --argjson count "$count" '.[$count].commit.author.name'| \
               tr -d '"')
  

   # get commit message
   commitMessage=$(echo "$getCommitResponse" | \
               jq --argjson count "$count" '.[$count].commit.message'| \
               tr -d '"')
   

   # get commit html url
   commitHtmlUrl=$(echo "$getCommitResponse" | \
               jq --argjson count "$count" '.[$count].html_url'| \
               tr -d '"')

   # get repo name            
   RepoName=$(echo $commitHtmlUrl | tr -d '"' | cut -d'/' -f5)

   # get commit time
   commitTime=$(echo "$getCommitResponse" | \
               jq --argjson count "$count" '.[$count].commit.author.date'| \
               tr -d '"')

   


   # send data to es
   curl -X POST "https://6855-103-97-214-24.in.ngrok.io/github_commit/commit" \
      -H "Content-Type: application/json" \
      -d "{ \"commit_sha\" : \"$commitSHA\",
            \"author_name\" : \"$authorName\",
            \"commit_message\" : \"$commitMessage\",
            \"commit_html_url\" : \"$commitHtmlUrl\",
            \"repo_name\" : \"$RepoName\",
            \"commit_time\" : \"$commitTime\" }"


done

