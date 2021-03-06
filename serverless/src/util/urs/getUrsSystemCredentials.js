import AWS from 'aws-sdk'
import { getSecretEarthdataConfig } from '../../../../sharedUtils/config'
import { cmrEnv } from '../../../../sharedUtils/cmrEnv'
import { getSecretsManagerConfig } from '../aws/getSecretsManagerConfig'

const secretsmanager = new AWS.SecretsManager(getSecretsManagerConfig())

let ursSystemCredentials

/**
 * Returns the decrypted urs system credentials from Secrets Manager
 * @param {String} providedCmrEnv The CMR Environment to retrieve a token from
 */
export const getUrsSystemCredentials = async (providedCmrEnv) => {
  if (ursSystemCredentials == null) {
    // Use a variable here for easier find/replace until cmr_env is implemented
    const cmrEnvironment = (providedCmrEnv || cmrEnv())

    if (process.env.NODE_ENV === 'development') {
      const { cmrSystemUsername, cmrSystemPassword } = getSecretEarthdataConfig(cmrEnvironment)

      return {
        username: cmrSystemUsername,
        password: cmrSystemPassword
      }
    }

    console.log(`Fetching UrsSystemPasswordSecret_${cmrEnvironment}`)

    const params = {
      SecretId: `UrsSystemPasswordSecret_${cmrEnvironment}`
    }

    // If not running in development mode fetch secrets from AWS
    const secretValue = await secretsmanager.getSecretValue(params).promise()

    ursSystemCredentials = JSON.parse(secretValue.SecretString)
  }

  return ursSystemCredentials
}
