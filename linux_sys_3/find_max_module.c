#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/moduleparam.h>
#include <linux/stat.h>
#include <linux/slab.h>
#include <linux/limits.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("longsontuyen");
MODULE_DESCRIPTION("Finds the maximum value and its indices in an integer array parameter.");

#define MAX_ARRAY_SIZE 16
static int input_array[MAX_ARRAY_SIZE];
static int num_elements = 0;

module_param_array(input_array, int, &num_elements, S_IRUGO);
MODULE_PARM_DESC(input_array, "Input integer array (comma-separated, max 16 elements).");

static int __init find_max_init(void) {
    int i;
    int max_val = INT_MIN;
    int count = 0;
    int max_indices[MAX_ARRAY_SIZE];

    printk(KERN_INFO "Find Max Module: Initializing...\n");

    if (num_elements <= 0) {
        printk(KERN_ERR "No elements provided in input_array. Please provide data like: input_array=1,2,3\n");
        return -EINVAL;
    }
    if (num_elements > MAX_ARRAY_SIZE) {
        printk(KERN_ERR "Number of elements (%d) exceeds maximum allowed size (%d).\n", num_elements, MAX_ARRAY_SIZE);
        return -EINVAL;
    }

    {
        char array_str[256];
        int offset = 0;
        int ret;
        ret = snprintf(array_str + offset, sizeof(array_str) - offset, "Received %d element(s): [", num_elements);
        if (ret > 0) offset += ret;

        for (i = 0; i < num_elements; i++) {
            ret = snprintf(array_str + offset, sizeof(array_str) - offset, "%d%s", input_array[i], (i == num_elements - 1) ? "" : ", ");
            if (ret < 0 || ret >= sizeof(array_str) - offset) {
                printk(KERN_WARNING "Input array string truncated.\n");
                break;
            }
            offset += ret;
        }
        snprintf(array_str + offset, sizeof(array_str) - offset, "]");
        printk(KERN_INFO "%s\n", array_str);
    }

    for (i = 0; i < num_elements; i++) {
        if (input_array[i] > max_val) {
            max_val = input_array[i];
        }
    }
    printk(KERN_INFO "Maximum value found: %d\n", max_val);

    count = 0;
    for (i = 0; i < num_elements; i++) {
        if (input_array[i] == max_val) {
            if (count < MAX_ARRAY_SIZE) {
                max_indices[count] = i;
                count++;
            } else {
                printk(KERN_WARNING "More occurrences of max value found than index storage allows (%d).\n", MAX_ARRAY_SIZE);
                break;
            }
        }
    }

    if (count > 0) {
        char indices_str[256];
        int offset = 0;
        int ret;
        ret = snprintf(indices_str + offset, sizeof(indices_str) - offset, "Found at index/indices: [");
        if (ret > 0) offset += ret;

        for(i = 0; i < count; i++) {
            ret = snprintf(indices_str + offset, sizeof(indices_str) - offset, "%d%s", max_indices[i], (i == count - 1) ? "" : ", ");
            if (ret < 0 || ret >= sizeof(indices_str) - offset) {
                printk(KERN_WARNING "Indices string truncated.\n");
                break;
            }
            offset += ret;
        }
        snprintf(indices_str + offset, sizeof(indices_str) - offset, "]");
        printk(KERN_INFO "%s\n", indices_str);
    } else {
        printk(KERN_WARNING "Could not find any index for the maximum value (this should not happen!).\n");
    }

    return 0;
}

static void __exit find_max_exit(void) {
    printk(KERN_INFO "Find Max Module: Exiting...\n");
}

module_init(find_max_init);
module_exit(find_max_exit);
