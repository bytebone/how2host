# The VPS Guides Project
> We need a better name for this

## Idea and Motivation

The guides available on the internet for setting up self-hosted apps are lacking and insufficient as they are spread out across different websites, leaving users feeling frustrated and confused. Official documentation of apps also falls short of providing in-depth information, making it difficult for users to configure and secure their apps properly. To bridge this gap and offer a seamless and comprehensive documentation experience, we aim to create a central documentation that includes all the necessary setup and securing advice in one place.

**Attention!** Due to the currently small team of authors, there is a certain bias to some apps over others, even when there are alternative options available. Therefore, we welcome and encourage contributions from users to help make our collection of guides more versatile and inclusive of different perspectives and experiences.

If you are interested in contributing to our guides, please check the pinned issue for the list of currently wanted topics, and leave a comment in that thread to claim one. We welcome all kinds of contributions, whether they are minor or major corrections, extensions, or additions.

## Contributing

    Clone the repo
    $ git clone https://github.com/justrainer/selfhost-guides
    
    Install dependencies
    $ npm install

    Run the dev environment
    $ npm run start

    Build a local version of the final website
    (usually not needed)
    $ npm run build

**Before making a PR with a new version or guide added, make sure to build the website once to make sure it goes through with no errors or warnings.**

The official documentation, with all the available components and icons, can be found [here](https://retype.com/components/). Before starting your work, please make yourself familiar with the available components, since there are many helpful tools that might make your guide easier to structure and therefore read.

## Formatting guidelines

1. If writing a new app guide, use the [app template](src/apps/_template.md?plain=1) as reference
2. Leave blank lines after every heading
3. When linking to either internal or outside sources, especially for the prerequisites and the source / official docs links, use the [reference links](https://retype.com/components/reference-link/) provided by Retype for better visibility
4. When pasting compose files, use code blocks along with "yaml" specification and filename declaration for clarity
5. When writing app guides, **always** put them in a subdirectory named after the app / task. the Markdown file should be called `readme.md` for easy display on GitHub. Place additional files required for this guide in the same directory.