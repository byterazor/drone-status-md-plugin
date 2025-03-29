local architectures = ["amd64","arm64"];

local image_name = "drone-md-status";

local github_repo_name = "drone-status-md-plugin";
local github_desc = "drone plugin for generating a basic status file in markdown";
local url = "https://gitea.federationhq.de/Container/drone-status-md-plugin";

local version_1_0_0 = 
{
    tag: "1.0.0",
    additional_tags: ["1.0","1"],
    dir: ".",
};


local versions = [version_1_0_0];


local build_steps(versions,arch) = [
    {
        name: "Build " + version.tag,
        image: "quay.io/buildah/stable",
        privileged: true,
        volumes:
        [
        {
            name: "fedhq-ca-crt",
            path: "/etc/ssl/certs2/"

        }
        ],
        commands: [
            "scripts/setupEnvironment.sh",
            "cd " + version.dir + ";" + 'buildah bud --network host -t "registry.cloud.federationhq.de/' + image_name + ':' +version.tag + "-" + arch + '" --arch ' + arch,
            'buildah push --all registry.cloud.federationhq.de/'+ image_name+':'+version.tag + "-" + arch

        ]
    }
    for version in versions
];

local build_pipelines(architectures) = [
    {
        kind: "pipeline",
        type: "kubernetes",
        name: "build-"+arch,
        platform: {
            arch: arch
        },
        volumes:
            [
                {
                    name: "fedhq-ca-crt",
                    config_map:
                    {
                        name: "fedhq-ca-crt",
                        default_mode: 420,
                        optional: false
                    },

                }
            ],
        node_selector:
        {
            'kubernetes.io/arch': arch,
            'federationhq.de/compute': true
        },
        steps: build_steps(versions, arch),
    }
    for arch in architectures
];



local push_pipelines(versions, architectures) = [
    {
        kind: "pipeline",
        type: "kubernetes",
        name: "push-"+version.tag,
        platform: {
            arch: "amd64"
        },
        volumes:
            [
                {
                    name: "fedhq-ca-crt",
                    config_map:
                    {
                        name: "fedhq-ca-crt",
                        default_mode: 420,
                        optional: false
                    },

                }
            ],
        node_selector:
        {
            'kubernetes.io/arch': "amd64",
            'federationhq.de/compute': true
        },
        depends_on: [
            "build-"+arch
            for arch in architectures
        ],
        steps:
            [   
                {
                    name: "Push " + version.tag,
                    image: "quay.io/buildah/stable",
                    privileged: true,
                    environment:
                        {
                            USERNAME: 
                            {
                                from_secret: "username"
                            },
                            PASSWORD:
                            {
                                from_secret: "password"
                            }
                        },
                    volumes:
                    [
                        {
                            name: "fedhq-ca-crt",
                            path: "/etc/ssl/certs2/"

                        }
                    ],
                    commands:
                    [
                        "scripts/setupEnvironment.sh",
                        "buildah manifest create " + image_name + ":"+version.tag,
                    ]
                    +
                    [
                    "buildah manifest add " + image_name + ":" + version.tag + " registry.cloud.federationhq.de/" + image_name + ":"+version.tag + "-" + arch 
                    for arch in architectures
                    ]
                    +
                    [
                        "buildah manifest push --all " + image_name +":"+version.tag + " docker://registry.cloud.federationhq.de/" + image_name +":"+tag
                        for tag in [version.tag]+version.additional_tags
                    ]
                    +
                    [
                        "buildah login -u $${USERNAME} -p $${PASSWORD} registry.hub.docker.com",
                    ]
                    +
                    [
                        "buildah manifest push --all " + image_name + ":"+version.tag + " docker://registry.hub.docker.com/byterazor/" + image_name +":"+tag
                        for tag in [version.tag]+version.additional_tags
                    ]
                }
            ]
        }
        for version in versions
];

local push_github = {
    kind: "pipeline",
    type: "kubernetes",
    name: "mirror-to-github",
    node_selector: {
        "federationhq.de/location": "Blumendorf",
        "federationhq.de/compute": true
    },
    steps: [
        {
            name: "github-mirror",
            image: "registry.cloud.federationhq.de/drone-github-mirror:latest",
            pull: "always",
            settings: {
                GH_TOKEN: {
                    from_secret: "GH_TOKEN"
                },
                GH_REPO: "byterazor/" + github_repo_name,
                GH_REPO_DESC: github_desc,
                GH_REPO_HOMEPAGE: url
            }
        }
    ],
    depends_on:
    [
        "push-"+version.tag
            for version in versions
    ]
};



    build_pipelines(architectures) + push_pipelines(versions,architectures) + [push_github] +
    [
{
    kind: "secret",
    name: "GH_TOKEN",
    get:{
        path: "github",
        name: "token"
    }
},
{
    kind: "secret",
    name: "username",
    get:{
        path: "docker",
        name: "username"
    }
},
{
    kind: "secret",
    name: "password",
    get:{
        path: "docker",
        name: "secret"
    }
}
    ]