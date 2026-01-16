#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt

# -----------------------
# Raw data (copied from your table)
# Each entry = list of 10 measurements
# -----------------------

vm_counts = [3, 6, 9, 12]

# OpenTofu create times
opentofu_create = {
    3:  [6.128, 8.956, 4.666, 6.517, 6.281, 4.91, 5.886, 4.706, 5.859, 6.442],
    6:  [8.37, 6.92, 7.367, 7.693, 7.124, 7.522, 7.308, 7.321, 7.439, 10.454],
    9:  [7.293, 7.81, 11.031, 7.34, 6.603, 8.295, 9.637, 7.739, 7.445, 9.902],
    12: [10.971, 11.568, 10.434, 11.562, 12.094, 10.916, 10.822, 11.226, 10.675, 11.829]
}

# OpenTofu destroy times
opentofu_destroy = {
    3:  [26.508, 27.051, 26.643, 26.108, 26.317, 31.13, 27.021, 26.777, 29.915, 25.743],
    6:  [25.75, 27.076, 26.101, 25.945, 25.285, 25.81, 26.003, 25.102, 26.841, 25.561],
    9:  [27.303, 28.992, 26.51, 30.714, 27.613, 29.43, 27.662, 34.723, 30.775, 25.814],
    12: [28.244, 29.247, 30.111, 29.824, 29.868, 28.281, 29.843, 30.075, 29.756, 30.482]
}

# Ansible create times
ansible_create = {
    3:  [16.716, 14.325, 15.272, 14.875, 14.107, 15.465, 14.577, 13.988, 15.957, 14.4],
    6:  [22.43, 24.641, 23.62, 23.193, 22.487, 23.071, 23.037, 22.169, 22.35, 21.766],
    9:  [20.338, 19.564, 19.721, 20.548, 19.406, 19.437, 19.294, 19.442, 19.244, 19.632],
    12: [39.835, 38.913, 39.753, 38.072, 37.579, 39.667, 39.216, 38.679, 46.304, 41.806]
}

# Ansible destroy times
ansible_destroy = {
    3:  [11.056, 10.635, 11.344, 10.706, 11.538, 12.688, 11.931, 10.805, 11.32, 10.723],
    6:  [19.176, 18.905, 18.283, 18.714, 17.766, 19.663, 20.589, 18.639, 19.746, 17.687],
    9:  [16.689, 16.323, 15.118, 15.945, 15.24, 18.715, 15.158, 15.047, 16.057, 16.307],
    12: [30.895, 32.155, 31.948, 31.988, 32.775, 31.579, 31.237, 34.285, 33.392, 31.888]
}


def compute_avg_std(data_dict):
    """Return lists of averages and standard deviations ordered by vm_counts."""
    avgs = []
    stds = []
    for vm in vm_counts:
        values = np.array(data_dict[vm])
        avgs.append(values.mean())
        stds.append(values.std(ddof=1))  # sample standard deviation
    return avgs, stds


# Calculate stats
ot_create_avg, ot_create_std = compute_avg_std(opentofu_create)
ot_destroy_avg, ot_destroy_std = compute_avg_std(opentofu_destroy)

an_create_avg, an_create_std = compute_avg_std(ansible_create)
an_destroy_avg, an_destroy_std = compute_avg_std(ansible_destroy)


# -----------------------
# Plot 1: Create times
# -----------------------
plt.figure(figsize=(8, 5))
plt.errorbar(vm_counts, ot_create_avg, yerr=ot_create_std, fmt='o-', capsize=5, label="OpenTofu Create")
plt.errorbar(vm_counts, an_create_avg, yerr=an_create_std, fmt='s-', capsize=5, label="Ansible Create")

plt.xlabel("VM Count")
plt.ylabel("Average Create Time [s]")
plt.title("Average VM Creation Time vs VM Count")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()


# -----------------------
# Plot 2: Destroy times
# -----------------------
plt.figure(figsize=(8, 5))
plt.errorbar(vm_counts, ot_destroy_avg, yerr=ot_destroy_std, fmt='o-', capsize=5, label="OpenTofu Destroy")
plt.errorbar(vm_counts, an_destroy_avg, yerr=an_destroy_std, fmt='s-', capsize=5, label="Ansible Destroy")

plt.xlabel("VM Count")
plt.ylabel("Average Destroy Time [s]")
plt.title("Average VM Destruction Time vs VM Count")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
