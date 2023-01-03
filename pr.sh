#!/bin/bash

getPrResponse=$(curl -s \
                    -H "Accept: application/vnd.github+json" \
                    -H "X-GitHub-Api-Version: 2022-11-28" \
                    'https://api.github.com/repos/NaincyKumariKnoldus/Github_logs/pulls?state=all&per_page=100&page=1')
echo $getPrResponse
# get number of PR
commitSHA=$(echo "$getPrResponse" | \
            jq '.[].id'| \
            tr -d '"')

echo $commitSHA

loopCount=$(echo "$commitSHA" | \
            wc -w)

echo $loopCount


for (( count=0; count<$loopCount; count++))
do
   # get PR html url
  PrHtmlUrl=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].html_url'| \
               tr -d '"')
   

   # get PR Body
  PrBody=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].head.base.repo.name'| \
               tr -d '"')


   # get Repo name
  RepoName=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].head.repo.name'| \
               tr -d '"')

# get PR Number
  PrNumber=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].number'| \
               tr -d '"')
  

# get PR Title
  PrTitle=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].title'| \
               tr -d '"')
  


# get PR state
  PrState=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].state'| \
               tr -d '"')
  

# get PR created at
  PrCreatedAt=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].created_at'| \
               tr -d '"')


# get PR closed at
  PrCloseAt=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].closed_at'| \
               tr -d '"')
 

# get PR merged at
  PrMergedAt=$(echo "$getPrResponse" | \
               jq --argjson count "$count" '.[$count].merged_at'| \
               tr -d '"')


# send data to es
   curl -X POST "https://72d5-103-97-214-105.in.ngrok.io/github_pull_request/PR" \
      -H "Content-Type: application/json" \
      -d "{ \"pr_number\" : \"$PrNumber\",
            \"pr_url\" : \"$PrHtmlUrl\",
            \"pr_title\" : \"$PrTitle\",
            \"repo_name\" : \"$RepoName\",
            \"pr_body\" : \"$PrBody\",
            \"pr_state\" : \"$PrState\",
            \"pr_creation_time\" : \"$PrCreatedAt\",
            \"pr_closed_time\" : \"$PrCloseAt\",
            \"pr_merge_at\" : \"$PrMergedAt\"}"

done

