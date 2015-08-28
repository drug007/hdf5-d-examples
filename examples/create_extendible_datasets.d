module create_extendible_datasets;

import std.stdio: writeln, writef;
import hdf5.hdf5;
import common;

enum datasetName = "ExtendibleArray";
enum Rank = 2;

void
main()
{
    hid_t       file;                          /* handles */
    hid_t       dataspace, dataset;  
    hid_t       filespace;                   
    hid_t       cparms;                     
    hid_t       memspace;

    hsize_t[2]  dims  = [ 3, 3 ];           /* dataset dimensions            
                                                  at creation time */
    hsize_t[2]  dims1 = [ 3, 3 ];           /* data1 dimensions */ 
    hsize_t[2]  dims2 = [ 7, 1 ];           /* data2 dimensions */  

    hsize_t[2]  maxdims = [ H5S_UNLIMITED, H5S_UNLIMITED ];
    hsize_t[2]  size;
    version(none) hssize_t[2] offset;
    ulong[2]    offset;
    //hsize_t      i,j;
    herr_t      status, status_n;                             
    int[3][3]   data1 = [ [1, 1, 1],      /* data to write */
                          [1, 1, 1],
                          [1, 1, 1] ];      

    int[7]      data2 = [ 2, 2, 2, 2, 2, 2, 2];

    /* Variables used in reading data back */
    hsize_t[2]  chunk_dims = [ 2, 5 ];
    hsize_t[2]  chunk_dimsr;
    hsize_t[2]  dimsr;
    int[10][3]  data_out;
    int         rank, rank_chunk;

    /* Create the data space with unlimited dimensions. */
    dataspace = H5Screate_simple (Rank, dims.ptr, maxdims.ptr); 

    /* Create a new file. If file exists its contents will be overwritten. */
    file = H5Fcreate (fileName, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    // Modify dataset creation properties, i.e. enable chunking  
    cparms = H5Pcreate (H5P_DATASET_CREATE);
    assert(cparms != -1);
    
    status = H5Pset_chunk (cparms, Rank, chunk_dims.ptr);
    assert(status >= 0);

    /* Create a new dataset within the file using cparms
       creation properties.  */
    dataset = H5Dcreate2 (file, datasetName, H5T_NATIVE_INT, dataspace,
                         //H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
                         H5P_DEFAULT, cparms, H5P_DEFAULT);

    /* Extend the dataset. This call assures that dataset is 3 x 3.*/
    size[0]   = 3; 
    size[1]   = 3; 
    status = H5Dset_extent (dataset, size.ptr);

    /* Select a hyperslab  */
    filespace = H5Dget_space (dataset);
    offset[0] = 0;
    offset[1] = 0;
    status = H5Sselect_hyperslab (filespace, H5S_seloper_t.H5S_SELECT_SET, offset.ptr, null,
                                  dims1.ptr, null);  

    /* Write the data to the hyperslab  */
    status = H5Dwrite (dataset, H5T_NATIVE_INT, dataspace, filespace,
                       H5P_DEFAULT, data1.ptr);

    /* Extend the dataset. Dataset becomes 10 x 3  */
    dims[0]   = dims1[0] + dims2[0];
    size[0]   = dims[0];  
    size[1]   = dims[1]; 
    status = H5Dset_extent (dataset, size.ptr);

    /* Select a hyperslab  */
    filespace = H5Dget_space (dataset);
    offset[0] = 3;
    offset[1] = 0;
    status = H5Sselect_hyperslab (filespace, H5S_seloper_t.H5S_SELECT_SET, offset.ptr, null,
                                  dims2.ptr, null);  

    /* Define memory space */
    dataspace = H5Screate_simple (Rank, dims2.ptr, null); 

    /* Write the data to the hyperslab  */
    status = H5Dwrite (dataset, H5T_NATIVE_INT, dataspace, filespace,
                       H5P_DEFAULT, data2.ptr);

    /* Close resources */
    status = H5Dclose (dataset);
    status = H5Sclose (dataspace);
    status = H5Sclose (filespace);
    status = H5Fclose (file);

/****************************************************************
    Read the data back 
 ***************************************************************/

    file = H5Fopen (fileName, H5F_ACC_RDONLY, H5P_DEFAULT);
    dataset = H5Dopen2 (file, datasetName, H5P_DEFAULT);
    filespace = H5Dget_space (dataset);
    rank = H5Sget_simple_extent_ndims (filespace);
    status_n = H5Sget_simple_extent_dims (filespace, dimsr.ptr, null);

    cparms = H5Dget_create_plist (dataset);
    if (H5D_layout_t.H5D_CHUNKED == H5Pget_layout (cparms))
    {
       rank_chunk = H5Pget_chunk (cparms, 2, chunk_dimsr.ptr);
    }

    memspace = H5Screate_simple (rank, dimsr.ptr, null);
    status = H5Dread (dataset, H5T_NATIVE_INT, memspace, filespace,
                      H5P_DEFAULT, data_out.ptr);
    writeln;
    writeln("Dataset:");
    foreach (j; 0..dimsr[0])
    {
       foreach (i; 0..dimsr[1])
           writef("%d ", data_out[i][j]);
       writeln;
    }

    status = H5Pclose (cparms);
    status = H5Dclose (dataset);
    status = H5Sclose (filespace);
    status = H5Sclose (memspace);
    status = H5Fclose (file);
}