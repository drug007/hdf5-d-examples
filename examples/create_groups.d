module create_groups;

import hdf5.hdf5;
import common;

void main()
{
    /* Create a new file using default properties. */
    auto file_id = H5Fcreate(fileName, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    /* Create group "MyGroup" in the root group using absolute name. */
    auto group1_id = H5Gcreate2(file_id, "/MyGroup", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    /* Create group "Group_A" in group "MyGroup" using absolute name. */
    auto group2_id = H5Gcreate2(file_id, "/MyGroup/Group_A", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    /* Create group "Group_B" in group "MyGroup" using relative name. */
    auto group3_id = H5Gcreate2(group1_id, "Group_B", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    /* Close groups. */
    auto 
    status = H5Gclose(group1_id);
    status = H5Gclose(group2_id);
    status = H5Gclose(group3_id);

    /* Close the file. */
    status = H5Fclose(file_id);
}
