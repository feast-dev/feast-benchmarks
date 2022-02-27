from datetime import datetime
from example import entity, feature_views, feature_services
from feast import FeatureStore

def main():

    fs = FeatureStore(repo_path=".")

    fs.apply([entity])
    [fs.apply([fv]) for fv in feature_views]
    [fs.apply([fv]) for fv in feature_services]

    fs.materialize_incremental(end_date=datetime.now())

if __name__ == "__main__":
    main()
