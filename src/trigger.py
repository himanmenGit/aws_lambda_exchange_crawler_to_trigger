import boto3

BITHUMB = 'bithumb'
COINONE = 'coinone'


def trigger_func(event, context):
    lambda_list = [
        BITHUMB, COINONE
    ]

    client_lambda = boto3.client('lambda')

    for site in lambda_list:
        response = client_lambda.invoke(
            FunctionName='crawler_crawler',
            InvocationType='Event',  # 비동기
            LogType='None',
            Payload='{' + '{}:"{}"'.format('"site"', site) + '}',
        )
        print('{} - {}'.format(site, response.get('ResponseMetadata').get('HTTPStatusCode')))
    return {
        'status': 200,
        'message': '트리거 작동'
    }
