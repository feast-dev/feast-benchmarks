import click
import json
import numpy as np


FEATURES_PER_VIEW = 10

@click.command()
@click.option('--features', default=250, help='Number of features')
@click.option('--entity-rows', default=1, help='Number of rows per request')
@click.option('--entity-keyspace', default=10**4, help='Entities range')
@click.option('--requests', default=10**3, help='Number of requests')
@click.option('--project', default="feature_repo")
@click.option('--output', default='requests.json')
def generate_requests(features, entity_rows, entity_keyspace, requests, project, output):
 	rs = []
 	feature_refs = [
 		f"feature_view_{feature_idx // FEATURES_PER_VIEW}:feature_{feature_idx}"
 		for feature_idx in range(features)
 	]

 	for _ in range(requests):
 		entities = [
 			dict(int64_val=int(key))		
 			for key in np.random.randint(1, entity_keyspace, entity_rows)
 		]

 		rs.append(dict(
 			features={"val": feature_refs},
 			entities={"entity": {"val": entities}}
 		))

 	with open(output, 'w') as f:
 		json.dump(rs, f)

    

if __name__ == '__main__':
    generate_requests()