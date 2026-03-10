Since you almost certainly want to use your own data for experiments, here are
a few common methods for migrating data to the Wafer-Scale Cluster. In general,
any method for transferring files via the internet will work, though note the
Wafer-Scale Cluster is hosted inside a Cerebras datacenter and so doesn't have
integration with PSC's globus or other institutional file-sharing infrastructure.

If you're familiar with file transfer toolings and protocols, you likely have
ideas on how best to migrate your data onto the cluster and so I won't
go through all options here. If you're not familiar, though, I recommend
starting with these simple tools. If you need something more robust or have
any questions, please reach out to me at sylvia.howland@cerebras.net.



1. Simple `scp` or `rsync`.
Useful tools for migrating data from one host filesystem to another. `scp` is
great for simple, one-time transfers and is a simpler command line tool to use,
whereas `rsync` is able to resume interrupted transfers among many other useful
features. You can find basic examples at the following URLs or by entering
`man scp` or `man rsync` in the command line.

scp: https://linuxblog.io/linux-securely-copy-files-using-scp/
rsync: https://linuxcommunity.io/t/rsync-command-in-linux-with-examples/3697

If transferring large datasets, it's typically best to compress the dataset
directory first with `zip` or `tar` to reduce its size.

zip: https://www.geeksforgeeks.org/linux-unix/zip-command-in-linux-with-examples/
tar: https://www.geeksforgeeks.org/linux-unix/tar-command-linux-examples/

2. Github and git-lfs.
Better for transferring code and other small files than for data, git-lfs
(Large File Storage) makes it possible to transfer reasonably-sized datasets.
Great for version control, and with plenty of documentation. If you're not
familiar, you can learn more below:

github: https://docs.github.com/en/get-started
git-lfs: https://git-lfs.com/
