
Deleting a Snapshots in a aws console Using Shell Script……
#!/bin/bash
#Author: Ashok
#Descr: Deleting a Snapshots
#date:2022-09-19

echo "Deleting a Snapshots in a aws console"
echo ".................................................."
#aws ec2 describe-snapshots --profile new-dev
AWS_DEFAULT=us-east-1
AWS_OWNER_ID=479348965617
echo "......................................."
SNAPSHOTIDS=`aws ec2 --region=${AWS_DEFAULT}  describe-snapshots --owner-ids=${AWS_OWNER_ID} --query 'Snapshots[*].SnapshotId' --output=text`
echo ".................................................."
for snap in $SNAPSHOTIDS;
do
  echo "Deleting a My Snapshots Which is available in  North-Virginia Region"
  SNAP=`aws ec2 --region us-east-1 delete-snapshot --snapshot-id $snap`
  echo "..............................."
done..
•	TO GET SNAPSHOT ID:
	aws ec2 describe-snapshots --owner-ids $AWS_OWNER_ID --query 'sort_by(Snapshots, &StartTime)[-1].SnapshotId' --output text

