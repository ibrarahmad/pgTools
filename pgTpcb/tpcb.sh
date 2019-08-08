#!/bin/bash
if [ "$#" -ne 2 ];
then
   echo "Usage: pgbench.sh db dir"
   exit $?
fi
rm -rf $2
mkdir -p $2

echo "Bash version ${BASH_VERSION}"
echo `postgres --version`

echo "Starting PostgreSQL"
pg_ctl start
psql postgres -c 'show shared_buffers' >> $2/config.log
psql postgres -c 'show work_mem' >> $2/config.log
psql postgres -c 'show random_page_cost' >> $2/config.log
psql postgres -c 'show maintenance_work_mem'>> $2/config.log
psql postgres -c 'show synchronous_commit'>> $2/config.log
psql postgres -c 'show seq_page_cost' >> $2/config.log
psql postgres -c 'show max_wal_size'>> $2/config.log
psql postgres -c 'show checkpoint_timeout'>> $2/config.log
psql postgres -c 'show synchronous_commit'>> $2/config.log
psql postgres -c 'show checkpoint_completion_target'>> $2/config.log
psql postgres -c 'show autovacuum_vacuum_scale_factor'>> $2/config.log
psql postgres -c 'show effective_cache_size'>> $2/config.log
psql postgres -c 'show min_wal_size'>> $2/config.log
psql postgres -c 'show wal_compression'>> $2/config.log
dropdb $1
createdb $1

for s in 1
do  
  pgbench $1 -i -s $s
  for c in {1..64}
  do  	
    for i in {1..3}
    do
        psql $1 -c CHECKPOINT
	echo 'Benchmarking with scale' $s 'and clients' $c
        pgbench $1 -T 1 -j $c -c $c >> $2/results-$s.txt 
    done
  done
done
cat results/results.txt | grep 'including connections' |awk {'print$3'} >> $2/results.cvs
echo "Stopping PostgreSQL"

psql $1 -c CHECKPOINT
pg_ctl stop
