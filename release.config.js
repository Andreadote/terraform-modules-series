module.exports = {
    branches: "main",
    repositoryUrl: "https://github.com/Andreadote/terraform-modules-series.git//S3_module",
    plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/git',
    '@semantic-release/github']
    }