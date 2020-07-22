#!/bin/bash

# Output each line as it is executed (-x) and don't stop if any non zero exit codes are seen (+e)
set -x +e
mark-section "download inputs"


# SET VARIABLES
# Store the API key. Grants the script access to DNAnexus resources    
API_KEY=$(dx cat project-FQqXfYQ0Z0gqx7XG9Z2b4K43:mokaguys_nexus_auth_key)

#Download docker image
docker pull brentp/somalier:v0.2.10

# Create output/input folders
mkdir -p out/output/QC input_bams

cd input_bams
# Download BAM and BAI files
dx download ${project_name}:output/*primerclipped.bam* --auth ${API_KEY}
cd ..

tar -xf hs37d5.tar.gz

# For each BAM file downloaded run somelier extract
# Here, the directory 'sandbox' is mapped to the /home/dnanexus directory
# output files are saved into folder named somelier_extract_out
for bam in input_bams/*.bam;
do 
dx-docker run -v /home/dnanexus:/sandbox brentp/somalier:v0.2.10 somalier extract -s sandbox/sites.GRCh37.vcf.gz -f sandbox/hs37d5.fa  -d sandbox/somelier_extract_out sandbox/input_bams/$(basename $bam)
done

# Run Somelier relate, after cd'ing within the docker container to ensure the outputs are saved into the mapped folder
# Here, the directory 'somalier' is mapped to the /home/dnanexus directory
dx-docker run -v /home/dnanexus:/somalier brentp/somalier:v0.2.10 /bin/bash -c "cd somalier; somalier relate somelier_extract_out/*.somalier"

# move the outputs (saved in home folder) to the output folder
mv somalier*tsv out/output/QC/
mv somalier*html out/output/QC/

dx-upload-all-outputs --parallel
