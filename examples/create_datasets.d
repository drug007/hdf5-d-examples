module create_datasets;

import hdf5.hdf5;
import common;

void main ()
{
    /*
     *  Create two datasets within groups.
     */
    
    hid_t       file_id, group_id, dataset_id, dataspace_id;  /* identifiers */
    hsize_t[2]  dims;
    herr_t      status;
    int[3][3]   dset1_data;
    int[10][2]  dset2_data;

    /* Initialize the first dataset. */
    foreach (i; 0..3)
      foreach (j; 0..3)
         dset1_data[i][j] = j + 1;

    /* Initialize the second dataset. */
    foreach (i; 0..2)
      foreach (j; 0..10)
         dset2_data[i][j] = j + 1;

    /* Open an existing file. */
    file_id = H5Fopen(fileName, H5F_ACC_RDWR, H5P_DEFAULT);

    /* Create the data space for the first dataset. */
    dims[0] = 3;
    dims[1] = 3;
    dataspace_id = H5Screate_simple(2, dims.ptr, null);

    /* Create a dataset in group "MyGroup". */
    dataset_id = H5Dcreate2(file_id, "/MyGroup/dset1", H5T_STD_I32BE, dataspace_id,
                          H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    /* Write the first dataset. */
    status = H5Dwrite(dataset_id, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT,
                     dset1_data.ptr);

    /* Close the data space for the first dataset. */
    status = H5Sclose(dataspace_id);

    /* Close the first dataset. */
    status = H5Dclose(dataset_id);

    /* Open an existing group of the specified file. */
    group_id = H5Gopen2(file_id, "/MyGroup/Group_A", H5P_DEFAULT);

    /* Create the data space for the second dataset. */
    dims[0] = 2;
    dims[1] = 10;
    dataspace_id = H5Screate_simple(2, dims.ptr, null);

    /* Create the second dataset in group "Group_A". */
    dataset_id = H5Dcreate2(group_id, "dset2", H5T_STD_I32BE, dataspace_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    /* Write the second dataset. */
    status = H5Dwrite(dataset_id, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT,
                     dset2_data.ptr);

    /* Close the data space for the second dataset. */
    status = H5Sclose(dataspace_id);

    /* Close the second dataset */
    status = H5Dclose(dataset_id);

    /* Close the group. */
    status = H5Gclose(group_id);

    /* Close the file. */
    status = H5Fclose(file_id);
}
